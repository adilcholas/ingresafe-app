/// ─────────────────────────────────────────────────────────────────────────────
/// Ingresafe – Warning Engine
/// ─────────────────────────────────────────────────────────────────────────────
///
/// Generates user-facing warnings based on:
///   1. Ingredient-level risk profiles from the Risk Rule Engine.
///   2. User's health profile (allergies, conditions, dietary preferences).
///   3. Specific ingredient-condition interactions.
/// ─────────────────────────────────────────────────────────────────────────────

import '../../models/health_profile_model.dart';
import '../../models/ingredient_model.dart';

/// A structured warning with severity and context.
class ScanWarning {
  final String message;
  final String severity; // 'Critical', 'High', 'Medium', 'Info'
  final String? ingredientName;
  final String? conditionOrAllergen;

  const ScanWarning({
    required this.message,
    required this.severity,
    this.ingredientName,
    this.conditionOrAllergen,
  });

  Map<String, dynamic> toMap() => {
    'message': message,
    'severity': severity,
    'ingredientName': ingredientName,
    'conditionOrAllergen': conditionOrAllergen,
  };

  @override
  String toString() => '[$severity] $message';
}

class WarningEngine {
  /// ── Generate warnings for a scan result ──────────────────────────────────
  ///
  /// [ingredients]    – The detected ingredients with their risk data.
  /// [healthProfile]  – The user's configured health profile (nullable).
  ///
  /// Returns a prioritised list of warnings (critical first).
  static List<ScanWarning> generateWarnings({
    required List<IngredientModel> ingredients,
    HealthProfileModel? healthProfile,
  }) {
    final warnings = <ScanWarning>[];

    for (final ing in ingredients) {
      // 1. General risk warnings
      if (ing.riskLevel == 'Risky') {
        warnings.add(ScanWarning(
          message: '${ing.name} is flagged as HIGH RISK. ${ing.description}',
          severity: 'High',
          ingredientName: ing.name,
        ));
      }

      // 2. Health profile matching (personalised warnings)
      if (healthProfile != null) {
        // Check allergen match
        if (ing.allergenKey != null &&
            healthProfile.allergies
                .map((a) => a.toLowerCase())
                .contains(ing.allergenKey!.toLowerCase())) {
          warnings.add(ScanWarning(
            message:
                '⚠️ ALLERGEN ALERT: ${ing.name} contains ${ing.allergenKey} — '
                'you have this listed as an allergy!',
            severity: 'Critical',
            ingredientName: ing.name,
            conditionOrAllergen: ing.allergenKey,
          ));
        }

        // Check health condition match
        if (ing.conditionKey != null &&
            healthProfile.healthConditions
                .map((c) => c.toLowerCase())
                .contains(ing.conditionKey!.toLowerCase())) {
          warnings.add(ScanWarning(
            message:
                '⚠️ HEALTH ALERT: ${ing.name} may affect your ${ing.conditionKey} condition. '
                '${ing.description}',
            severity: 'Critical',
            ingredientName: ing.name,
            conditionOrAllergen: ing.conditionKey,
          ));
        }
      }
    }

    // 3. Aggregate warnings
    final riskyCount = ingredients.where((i) => i.riskLevel == 'Risky').length;
    final cautionCount =
        ingredients.where((i) => i.riskLevel == 'Caution').length;

    if (riskyCount >= 3) {
      warnings.add(ScanWarning(
        message:
            'This product contains $riskyCount high-risk ingredients. '
            'Consider a safer alternative.',
        severity: 'High',
      ));
    }

    if (cautionCount >= 5) {
      warnings.add(ScanWarning(
        message:
            '$cautionCount ingredients require caution. '
            'Moderate consumption is advised.',
        severity: 'Medium',
      ));
    }

    // Sort: Critical > High > Medium > Info
    warnings.sort((a, b) => _severityRank(a.severity).compareTo(_severityRank(b.severity)));

    return warnings;
  }

  static int _severityRank(String severity) {
    switch (severity) {
      case 'Critical':
        return 0;
      case 'High':
        return 1;
      case 'Medium':
        return 2;
      default:
        return 3;
    }
  }
}
