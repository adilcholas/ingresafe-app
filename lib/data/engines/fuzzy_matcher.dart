/// ─────────────────────────────────────────────────────────────────────────────
/// Ingresafe – Fuzzy Matching Engine (Levenshtein Distance)
/// ─────────────────────────────────────────────────────────────────────────────
///
/// Solves Issue #4: **Eliminating "Unknown" Ingredients**
///
/// When a user scans a product label via OCR, typos and artifacts are common:
///   - "Suger" → should match "Sugar"
///   - "Sodim Benzoate" → should match "Sodium Benzoate"
///   - "Artifical Flavor" → should match "Artificial Flavor"
///
/// This engine implements **Levenshtein Distance** (edit distance) to compare
/// scanned text tokens against the canonical ingredient dictionary built from
/// the 5,000-product dataset.
///
/// Algorithm:
///   1. Compute Levenshtein distance between the scanned token and every
///      ingredient in the dictionary.
///   2. If the distance is within the threshold (default: 2 for short words,
///      3 for longer words), accept the match.
///   3. Return the best match (lowest distance). Ties broken by alphabetical
///      order for determinism.
///
/// Complexity: O(n × m) per comparison where n, m are string lengths.
/// With 19 unique ingredients in the dataset, this is effectively instant.
/// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;

/// Result of a fuzzy match attempt.
class FuzzyMatchResult {
  final String original;
  final String matched;
  final int distance;
  final double similarity;
  final bool isExactMatch;

  const FuzzyMatchResult({
    required this.original,
    required this.matched,
    required this.distance,
    required this.similarity,
    required this.isExactMatch,
  });

  @override
  String toString() =>
      'FuzzyMatch("$original" → "$matched", distance=$distance, '
      'similarity=${(similarity * 100).toStringAsFixed(1)}%)';
}

class FuzzyMatcher {
  /// The canonical dictionary of known ingredients.
  final Set<String> _dictionary;

  /// Maximum allowed edit distance for a match to be accepted.
  /// Dynamically computed based on word length if not provided.
  final int? maxDistance;

  FuzzyMatcher({
    required Iterable<String> dictionary,
    this.maxDistance,
  }) : _dictionary = dictionary.map((s) => s.toLowerCase().trim()).toSet();

  /// ── Build from the 5,000-product dataset ─────────────────────────────────
  ///
  /// Extracts all unique ingredient names to form the canonical dictionary.
  factory FuzzyMatcher.fromProductDataset(List<Map<String, dynamic>> products) {
    final allIngredients = <String>{};

    for (final product in products) {
      final ingredients = product['ingredients'] as List<dynamic>? ?? [];
      for (final ing in ingredients) {
        final name = ing.toString().trim();
        if (name.isNotEmpty) {
          allIngredients.add(name.toLowerCase());
        }
      }
    }

    return FuzzyMatcher(dictionary: allIngredients);
  }

  /// ── Build from a known ingredient list ────────────────────────────────────
  factory FuzzyMatcher.fromIngredientList(List<String> ingredients) {
    return FuzzyMatcher(
      dictionary: ingredients.map((s) => s.toLowerCase().trim()),
    );
  }

  /// ── Match a single token ──────────────────────────────────────────────────
  ///
  /// Returns the best fuzzy match for [input], or `null` if no match is within
  /// the acceptable distance threshold.
  FuzzyMatchResult? match(String input) {
    final normalised = input.toLowerCase().trim();

    if (normalised.isEmpty) return null;

    // Exact match short-circuit
    if (_dictionary.contains(normalised)) {
      return FuzzyMatchResult(
        original: input,
        matched: _findOriginalCase(normalised),
        distance: 0,
        similarity: 1.0,
        isExactMatch: true,
      );
    }

    // Compute Levenshtein distance against all dictionary entries
    String? bestMatch;
    int bestDistance = 999;

    for (final entry in _dictionary) {
      final dist = levenshteinDistance(normalised, entry);

      if (dist < bestDistance) {
        bestDistance = dist;
        bestMatch = entry;
      } else if (dist == bestDistance && bestMatch != null) {
        // Tie-break: prefer shorter dictionary entries (more common names)
        if (entry.length < bestMatch.length) {
          bestMatch = entry;
        }
      }
    }

    if (bestMatch == null) return null;

    // Dynamic threshold based on word length
    final threshold = maxDistance ?? _dynamicThreshold(normalised.length);

    if (bestDistance > threshold) return null;

    final maxLen = math.max(normalised.length, bestMatch.length);
    final similarity = maxLen > 0 ? 1.0 - (bestDistance / maxLen) : 0.0;

    return FuzzyMatchResult(
      original: input,
      matched: _findOriginalCase(bestMatch),
      distance: bestDistance,
      similarity: similarity,
      isExactMatch: false,
    );
  }

  /// ── Match a list of tokens ────────────────────────────────────────────────
  ///
  /// Processes multiple ingredient tokens at once. Returns a map of
  /// original → matched name. Unmatched tokens are mapped to `null`.
  Map<String, FuzzyMatchResult?> matchAll(List<String> tokens) {
    final results = <String, FuzzyMatchResult?>{};
    for (final token in tokens) {
      results[token] = match(token);
    }
    return results;
  }

  /// ── Resolve a list: replace misspelled with correct names ─────────────────
  ///
  /// Returns a new list where every recognisable token is replaced with its
  /// canonical dictionary match. Unrecognised tokens are kept as-is.
  List<String> resolveAll(List<String> tokens) {
    return tokens.map((token) {
      final result = match(token);
      return result?.matched ?? token;
    }).toList();
  }

  /// ── Core: Levenshtein Distance (Wagner–Fischer algorithm) ────────────────
  ///
  /// Computes the minimum number of single-character edits (insertions,
  /// deletions, substitutions) required to change [source] into [target].
  ///
  /// Time:  O(n × m)
  /// Space: O(min(n, m)) — uses rolling two-row optimisation
  static int levenshteinDistance(String source, String target) {
    if (source == target) return 0;
    if (source.isEmpty) return target.length;
    if (target.isEmpty) return source.length;

    // Optimise: make the shorter string the "column" axis
    if (source.length > target.length) {
      final temp = source;
      source = target;
      target = temp;
    }

    final n = source.length;
    final m = target.length;

    // Rolling rows
    var previousRow = List<int>.generate(n + 1, (i) => i);
    var currentRow = List<int>.filled(n + 1, 0);

    for (int j = 1; j <= m; j++) {
      currentRow[0] = j;

      for (int i = 1; i <= n; i++) {
        final cost = source[i - 1] == target[j - 1] ? 0 : 1;

        currentRow[i] = [
          currentRow[i - 1] + 1,      // Insertion
          previousRow[i] + 1,          // Deletion
          previousRow[i - 1] + cost,   // Substitution
        ].reduce(math.min);
      }

      // Swap rows
      final temp = previousRow;
      previousRow = currentRow;
      currentRow = temp;
    }

    return previousRow[n];
  }

  /// ── Similarity score (0.0 – 1.0) ──────────────────────────────────────────
  ///
  /// Convenience method: `1 - (distance / maxLength)`.
  static double similarity(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    final maxLen = math.max(a.length, b.length);
    final dist = levenshteinDistance(a.toLowerCase(), b.toLowerCase());
    return 1.0 - (dist / maxLen);
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  /// Dynamic distance threshold:
  ///   Length ≤ 4  → max distance 1  (e.g., "Salt" → "Slt" but not "Water")
  ///   Length ≤ 8  → max distance 2  (e.g., "Suger" → "Sugar")
  ///   Length > 8  → max distance 3  (e.g., "Artifical Flavor" → "Artificial Flavor")
  static int _dynamicThreshold(int length) {
    if (length <= 4) return 1;
    if (length <= 8) return 2;
    return 3;
  }

  /// Look up the title-cased version of a dictionary entry.
  String _findOriginalCase(String lowercaseEntry) {
    // Return title-cased version
    return lowercaseEntry
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : w)
        .join(' ');
  }
}
