/// ─────────────────────────────────────────────────────────────────────────────
/// Ingresafe – Ingredient Risk Rule Engine
/// ─────────────────────────────────────────────────────────────────────────────
///
/// Solves Issue #2: **Ingredient-Level Risk Mapping**
///
/// Instead of assigning risk only at the product level, this engine calculates
/// an individual risk score and risk level for **every unique ingredient**
/// across the entire 5,000-product dataset.
///
/// Algorithm:
///   For each ingredient, count how many times it appears in High, Medium,
///   and Low risk products. Compute a weighted risk score:
///
///     risk_score = (high_count × 3 + medium_count × 1) / total_count
///
///   Then map to risk levels:
///     ≥ 2.0  → "High"
///     ≥ 1.0  → "Medium"
///     < 1.0  → "Low"
///
/// This produces the **Ingredient Master Collection** which can be stored in
/// Firestore and used for real-time per-ingredient risk badges in the UI.
/// ─────────────────────────────────────────────────────────────────────────────

/// Represents the computed risk profile for a single ingredient.
class IngredientRiskProfile {
  final String name;
  final int totalOccurrences;
  final int highRiskCount;
  final int mediumRiskCount;
  final int lowRiskCount;
  final double riskScore;
  final String riskLevel;

  const IngredientRiskProfile({
    required this.name,
    required this.totalOccurrences,
    required this.highRiskCount,
    required this.mediumRiskCount,
    required this.lowRiskCount,
    required this.riskScore,
    required this.riskLevel,
  });

  Map<String, dynamic> toFirestoreMap() => {
    'name': name,
    'normalized_name': name.toLowerCase(),
    'total_occurrences': totalOccurrences,
    'high_risk_count': highRiskCount,
    'medium_risk_count': mediumRiskCount,
    'low_risk_count': lowRiskCount,
    'risk_score': riskScore,
    'risk_level': riskLevel,
    'high_risk_percentage':
        totalOccurrences > 0
            ? (highRiskCount / totalOccurrences * 100).roundToDouble()
            : 0.0,
  };

  factory IngredientRiskProfile.fromFirestoreMap(Map<String, dynamic> map) {
    return IngredientRiskProfile(
      name: map['name'] as String? ?? '',
      totalOccurrences: map['total_occurrences'] as int? ?? 0,
      highRiskCount: map['high_risk_count'] as int? ?? 0,
      mediumRiskCount: map['medium_risk_count'] as int? ?? 0,
      lowRiskCount: map['low_risk_count'] as int? ?? 0,
      riskScore: (map['risk_score'] as num?)?.toDouble() ?? 0.0,
      riskLevel: map['risk_level'] as String? ?? 'Low',
    );
  }

  @override
  String toString() =>
      'IngredientRiskProfile($name: score=$riskScore level=$riskLevel '
      'total=$totalOccurrences H=$highRiskCount M=$mediumRiskCount L=$lowRiskCount)';
}

/// The risk rule engine that processes the full product dataset.
class RiskRuleEngine {
  /// ── Build the Ingredient Master Collection ─────────────────────────────────
  ///
  /// Takes the full labeled product list (from `products_5000_labeled.json`)
  /// and computes per-ingredient risk profiles.
  ///
  /// [products] – List of product maps, each containing:
  ///   - `ingredients`: List<String>
  ///   - `risk_level`: "High" | "Medium" | "Low"
  static List<IngredientRiskProfile> buildIngredientMaster(
    List<Map<String, dynamic>> products,
  ) {
    // Step 1: Accumulate counts per ingredient
    final stats = <String, _IngredientAccumulator>{};

    for (final product in products) {
      final riskLevel = (product['risk_level'] as String?) ?? 'Low';
      final ingredients = product['ingredients'] as List<dynamic>? ?? [];

      for (final rawIngredient in ingredients) {
        final name = rawIngredient.toString().trim();
        final key = name.toLowerCase();

        if (key.isEmpty) continue;

        stats.putIfAbsent(
          key,
          () => _IngredientAccumulator(displayName: name),
        );

        stats[key]!.total++;

        switch (riskLevel) {
          case 'High':
            stats[key]!.high++;
            break;
          case 'Medium':
            stats[key]!.medium++;
            break;
          default:
            stats[key]!.low++;
        }
      }
    }

    // Step 2: Compute weighted risk scores and classify
    final results = <IngredientRiskProfile>[];

    for (final entry in stats.entries) {
      final acc = entry.value;
      final score = _computeRiskScore(acc.high, acc.medium, acc.total);
      final level = _classifyRiskLevel(score);

      results.add(IngredientRiskProfile(
        name: acc.displayName,
        totalOccurrences: acc.total,
        highRiskCount: acc.high,
        mediumRiskCount: acc.medium,
        lowRiskCount: acc.low,
        riskScore: double.parse(score.toStringAsFixed(2)),
        riskLevel: level,
      ));
    }

    // Sort by risk score descending (most dangerous first)
    results.sort((a, b) => b.riskScore.compareTo(a.riskScore));

    return results;
  }

  /// ── Look up a single ingredient's risk ──────────────────────────────────────
  ///
  /// Given a pre-built master list and an ingredient name, returns its profile.
  static IngredientRiskProfile? lookupIngredient(
    List<IngredientRiskProfile> master,
    String ingredientName,
  ) {
    final key = ingredientName.toLowerCase().trim();
    try {
      return master.firstWhere((p) => p.name.toLowerCase() == key);
    } catch (_) {
      return null;
    }
  }

  /// ── Compute overall product risk from individual ingredient risks ─────────
  ///
  /// Takes a list of ingredient names found in a product and the master
  /// collection. Returns the aggregate product risk level.
  static String computeProductRisk(
    List<String> ingredientNames,
    List<IngredientRiskProfile> master,
  ) {
    if (ingredientNames.isEmpty) return 'Low';

    double totalScore = 0;
    int matched = 0;

    for (final name in ingredientNames) {
      final profile = lookupIngredient(master, name);
      if (profile != null) {
        totalScore += profile.riskScore;
        matched++;
      }
    }

    if (matched == 0) return 'Low';

    // Average risk score across all matched ingredients
    final avgScore = totalScore / matched;

    // Additional factor: ingredient count penalty
    // Products with many risky ingredients should rank higher
    final countPenalty = matched > 5 ? 0.2 : 0.0;

    final finalScore = avgScore + countPenalty;

    return _classifyRiskLevel(finalScore);
  }

  /// ── Get Top N High-Risk Ingredients ────────────────────────────────────────
  static List<IngredientRiskProfile> getTopHighRisk(
    List<IngredientRiskProfile> master, {
    int count = 10,
  }) {
    return master.take(count).toList();
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  /// Weighted risk score formula:
  ///   score = (highCount × 3 + mediumCount × 1) / totalCount
  ///
  /// This gives heavier weight to appearances in High-risk products.
  /// Max possible score = 3.0 (appears only in High products).
  static double _computeRiskScore(int high, int medium, int total) {
    if (total == 0) return 0.0;
    return (high * 3.0 + medium * 1.0) / total;
  }

  /// Classification thresholds:
  ///   ≥ 2.0 → High (ingredient predominantly appears in High-risk products)
  ///   ≥ 1.0 → Medium
  ///   < 1.0 → Low
  static String _classifyRiskLevel(double score) {
    if (score >= 2.0) return 'High';
    if (score >= 1.0) return 'Medium';
    return 'Low';
  }
}

/// Internal accumulator for counting ingredient occurrences.
class _IngredientAccumulator {
  final String displayName;
  int total = 0;
  int high = 0;
  int medium = 0;
  int low = 0;

  _IngredientAccumulator({required this.displayName});
}
