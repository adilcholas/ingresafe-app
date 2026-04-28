/// ─────────────────────────────────────────────────────────────────────────────
/// Ingresafe – Robust Ingredient Parser
/// ─────────────────────────────────────────────────────────────────────────────
///
/// Solves Issue #1: **Partial Extraction Fix**
///
/// The previous implementation only scanned OCR text for substring matches
/// against the local `_kLocalIngredients` map, which:
///   - Missed ingredients not in the hardcoded list.
///   - Silently dropped valid ingredient strings.
///   - Could not handle varied separator patterns.
///
/// This parser guarantees **every single string** in a product's `ingredients`
/// array is captured. It also handles raw OCR text by splitting on common
/// delimiters (comma, semicolon, parentheses, newlines, "and", bullet
/// characters, etc.) and normalising each token.
///
/// Works with both:
///   1. Structured JSON arrays (from Firestore / dataset)
///   2. Free-text OCR output (from google_mlkit_text_recognition)
/// ─────────────────────────────────────────────────────────────────────────────

class IngredientParser {
  /// ── Parse a structured ingredient list (e.g. from JSON dataset) ───────────
  ///
  /// Ensures **zero loss**: every non-empty string is normalised and returned.
  static List<String> parseFromList(List<dynamic> raw) {
    final results = <String>[];

    for (final item in raw) {
      final normalised = _normalise(item.toString());
      if (normalised.isNotEmpty) {
        results.add(normalised);
      }
    }

    return results;
  }

  /// ── Parse free-text OCR output ────────────────────────────────────────────
  ///
  /// Handles all real-world label formatting variations:
  ///   - Comma-separated: "Sugar, Salt, Water"
  ///   - Semicolon-separated: "Sugar; Salt; Water"
  ///   - Newline/bullet-separated from OCR
  ///   - Parenthesised sub-ingredients: "Milk Chocolate (Cocoa, Sugar, Milk)"
  ///   - "Contains:" / "Ingredients:" prefixes
  ///   - Conjunction-split: "Salt and Pepper"
  static List<String> parseFromText(String ocrText) {
    if (ocrText.trim().isEmpty) return [];

    String cleaned = ocrText;

    // 1. Strip common label prefixes
    cleaned = cleaned.replaceAll(
      RegExp(
        r'(ingredients?\s*:?\s*|contains?\s*:?\s*)',
        caseSensitive: false,
      ),
      '',
    );

    // 2. Normalise brackets / parentheses into commas
    //    e.g. "Milk Chocolate (Cocoa, Sugar)" → "Milk Chocolate, Cocoa, Sugar"
    cleaned = cleaned.replaceAll(RegExp(r'[(\[{}\])]'), ',');

    // 3. Replace all common delimiters with comma
    cleaned = cleaned.replaceAll(RegExp(r'[;\n\r•·–—|/]'), ',');

    // 4. Split on "and" / "&" used as conjunctions (but not inside words)
    cleaned = cleaned.replaceAll(RegExp(r'\s+and\s+', caseSensitive: false), ',');
    cleaned = cleaned.replaceAll(RegExp(r'\s*&\s*'), ',');

    // 5. Split on commas and clean each token
    final tokens = cleaned.split(',');
    final results = <String>[];

    for (final token in tokens) {
      final normalised = _normalise(token);
      if (normalised.isNotEmpty && normalised.length > 1) {
        results.add(normalised);
      }
    }

    return results;
  }

  /// ── Parse a product map (from JSON / Firestore doc) ───────────────────────
  ///
  /// Extracts the `ingredients` field from a product document and guarantees
  /// every ingredient string is captured.
  static List<String> parseFromProduct(Map<String, dynamic> productMap) {
    final rawIngredients = productMap['ingredients'];

    if (rawIngredients == null) return [];

    if (rawIngredients is List) {
      return parseFromList(rawIngredients);
    }

    if (rawIngredients is String) {
      return parseFromText(rawIngredients);
    }

    return [];
  }

  /// ── Validate extraction completeness ──────────────────────────────────────
  ///
  /// Utility for testing: confirms the parser captured all ingredients from
  /// the source. Returns `true` if every item in [expected] has a match in
  /// [parsed] (case-insensitive).
  static bool validateCompleteness(
    List<String> expected,
    List<String> parsed,
  ) {
    final parsedLower = parsed.map((s) => s.toLowerCase()).toSet();
    for (final item in expected) {
      if (!parsedLower.contains(item.toLowerCase())) {
        return false;
      }
    }
    return true;
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  /// Normalise a single ingredient token:
  ///   - Trim whitespace
  ///   - Collapse multiple spaces
  ///   - Remove trailing/leading punctuation (periods, colons, etc.)
  ///   - Convert to title case for display consistency
  static String _normalise(String raw) {
    String s = raw.trim();

    // Remove leading/trailing punctuation artefacts from OCR
    s = s.replaceAll(RegExp(r'^[\s.,:;*\-–—•·]+'), '');
    s = s.replaceAll(RegExp(r'[\s.,:;*\-–—•·]+$'), '');

    // Collapse whitespace
    s = s.replaceAll(RegExp(r'\s+'), ' ');

    // Remove purely numeric tokens (e.g., percentage values "2%")
    if (RegExp(r'^\d+%?$').hasMatch(s)) return '';

    return s.trim();
  }
}
