/// ─────────────────────────────────────────────────────────────────────────────
/// Ingresafe – Unified Analysis Service
/// ─────────────────────────────────────────────────────────────────────────────
///
/// This is the **main orchestrator** that ties together all four issue fixes
/// into a single service class:
///
///   1. Partial Extraction Fix     → IngredientParser
///   2. Ingredient-Level Risk      → RiskRuleEngine
///   3. Alternative Recommendations→ AlternativeEngine
///   4. Fuzzy Matching             → FuzzyMatcher
///
/// The service maintains:
///   - A precomputed Ingredient Master Collection (risk profiles)
///   - A fuzzy matcher dictionary built from the dataset
///   - Methods for processing scan results end-to-end
///
/// Usage in Flutter:
///   ```dart
///   // Initialise once at app startup (e.g., in main.dart)
///   await IngresafeAnalysisService.initialize(products);
///
///   // Process a scan
///   final result = IngresafeAnalysisService.processScan(
///     ocrText: rawOcrText,
///     productCategory: 'Beverage',
///   );
///   ```
/// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../models/health_profile_model.dart';
import '../../models/ingredient_model.dart';
import '../engines/alternative_engine.dart';
import '../engines/fuzzy_matcher.dart';
import '../engines/risk_rule_engine.dart';
import '../engines/warning_engine.dart';
import '../parsers/ingredient_parser.dart';
import 'ingredient_data_service.dart';

/// Complete scan analysis result containing all outputs.
class AnalysisResult {
  final List<String> extractedIngredients;
  final List<String> resolvedIngredients; // After fuzzy matching
  final List<IngredientRiskProfile> ingredientRisks;
  final String overallRiskLevel;
  final List<AlternativeRecommendation> alternatives;
  final List<ScanWarning> warnings;
  final List<IngredientModel> ingredientModels;
  final Map<String, FuzzyMatchResult?> fuzzyMatches;

  const AnalysisResult({
    required this.extractedIngredients,
    required this.resolvedIngredients,
    required this.ingredientRisks,
    required this.overallRiskLevel,
    required this.alternatives,
    required this.warnings,
    required this.ingredientModels,
    required this.fuzzyMatches,
  });
}

class IngresafeAnalysisService {
  // ── Singletons ────────────────────────────────────────────────────────────
  static List<IngredientRiskProfile>? _ingredientMaster;
  static FuzzyMatcher? _fuzzyMatcher;
  static bool _isInitialised = false;

  /// ── Initialise from the embedded JSON dataset ──────────────────────────────
  ///
  /// Call this once at app startup. Loads `products_5000_labeled.json` from
  /// the bundled assets, builds the ingredient master collection, and
  /// initialises the fuzzy matcher.
  static Future<void> initializeFromAsset() async {
    try {
      debugPrint('[IngresafeAnalysisService] Loading dataset from assets...');
      final jsonString = await rootBundle.loadString(
        'lib/data/json/products_5000_labeled.json',
      );
      final List<dynamic> rawProducts = json.decode(jsonString);
      final products = rawProducts
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList();

      initialize(products);
    } catch (e) {
      debugPrint('[IngresafeAnalysisService] Asset load failed: $e');
      // Fall back to hardcoded dataset ingredients
      _initializeFallback();
    }
  }

  /// ── Initialise from a pre-loaded product list ──────────────────────────────
  static void initialize(List<Map<String, dynamic>> products) {
    debugPrint(
      '[IngresafeAnalysisService] Building master from ${products.length} products...',
    );

    // Build ingredient master collection (Issue #2)
    _ingredientMaster = RiskRuleEngine.buildIngredientMaster(products);
    debugPrint(
      '[IngresafeAnalysisService] Master built: ${_ingredientMaster!.length} ingredients',
    );

    // Build fuzzy matcher dictionary (Issue #4)
    _fuzzyMatcher = FuzzyMatcher.fromProductDataset(products);
    debugPrint('[IngresafeAnalysisService] Fuzzy matcher initialised');

    _isInitialised = true;

    // Log top 10 high-risk ingredients
    final top10 = RiskRuleEngine.getTopHighRisk(_ingredientMaster!, count: 10);
    debugPrint('[IngresafeAnalysisService] Top 10 High-Risk Ingredients:');
    for (int i = 0; i < top10.length; i++) {
      debugPrint(
        '  ${i + 1}. ${top10[i].name} — score: ${top10[i].riskScore}, '
        'high: ${top10[i].highRiskCount}/${top10[i].totalOccurrences}',
      );
    }
  }

  /// Fallback initialisation with the dataset ingredients we know about.
  static void _initializeFallback() {
    debugPrint('[IngresafeAnalysisService] Using fallback ingredient list');
    final knownIngredients = [
      'Parabens', 'High Fructose Corn Syrup', 'Sodium Benzoate', 'Sugar',
      'MSG', 'SLS', 'Palm Oil', 'Butter', 'Potassium Sorbate', 'Salt',
      'Milk', 'Refined Flour', 'Wheat', 'Propylene Glycol', 'Cocoa',
      'Artificial Flavor', 'Corn', 'Caramel Color', 'Fragrance',
    ];

    _fuzzyMatcher = FuzzyMatcher.fromIngredientList(knownIngredients);
    _ingredientMaster = []; // Empty master — will rely on IngredientDataService
    _isInitialised = true;
  }

  /// ── Process a full scan ──────────────────────────────────────────────────
  ///
  /// End-to-end pipeline:
  ///   1. Parse OCR text → extract all ingredients (Issue #1)
  ///   2. Fuzzy match each token to eliminate unknowns (Issue #4)
  ///   3. Look up per-ingredient risk profiles (Issue #2)
  ///   4. Compute overall product risk
  ///   5. Generate alternative recommendations (Issue #3)
  ///   6. Generate personalised warnings
  static Future<AnalysisResult> processScan({
    required String ocrText,
    String productCategory = 'Food',
    HealthProfileModel? healthProfile,
  }) async {
    _ensureInitialised();

    // ── Step 1: Extract ingredients (Issue #1) ──────────────────────────────
    final extractedRaw = IngredientParser.parseFromText(ocrText);

    // ── Step 2: Fuzzy match to resolve misspellings (Issue #4) ──────────────
    final fuzzyResults = _fuzzyMatcher!.matchAll(extractedRaw);
    final resolvedIngredients = extractedRaw.map((token) {
      final match = fuzzyResults[token];
      return match?.matched ?? token;
    }).toList();

    // ── Step 3: Look up per-ingredient risk profiles (Issue #2) ─────────────
    final ingredientRisks = <IngredientRiskProfile>[];
    for (final name in resolvedIngredients) {
      final profile = RiskRuleEngine.lookupIngredient(
        _ingredientMaster!,
        name,
      );
      if (profile != null) {
        ingredientRisks.add(profile);
      }
    }

    // ── Step 4: Compute overall product risk ────────────────────────────────
    final overallRisk = RiskRuleEngine.computeProductRisk(
      resolvedIngredients,
      _ingredientMaster!,
    );

    // ── Step 5: Get IngredientModel details from the data service ───────────
    final ingredientModels = await IngredientDataService.parseIngredientsFromText(
      resolvedIngredients.join(', '),
    );

    // ── Step 6: Generate alternatives (Issue #3) ────────────────────────────
    final alternatives = AlternativeEngine.getAlternatives(
      productCategory: productCategory,
      ingredientNames: resolvedIngredients,
    );

    // ── Step 7: Generate warnings ───────────────────────────────────────────
    final warnings = WarningEngine.generateWarnings(
      ingredients: ingredientModels,
      healthProfile: healthProfile,
    );

    return AnalysisResult(
      extractedIngredients: extractedRaw,
      resolvedIngredients: resolvedIngredients,
      ingredientRisks: ingredientRisks,
      overallRiskLevel: overallRisk,
      alternatives: alternatives,
      warnings: warnings,
      ingredientModels: ingredientModels,
      fuzzyMatches: fuzzyResults,
    );
  }

  /// ── Process a structured ingredient list (from JSON / Firestore) ─────────
  ///
  /// For when you already have a product's ingredient array.
  static Future<AnalysisResult> processIngredientList({
    required List<dynamic> ingredients,
    String productCategory = 'Food',
    HealthProfileModel? healthProfile,
  }) async {
    _ensureInitialised();

    // Step 1: Parse (Issue #1 — guaranteed zero-loss)
    final extractedRaw = IngredientParser.parseFromList(ingredients);

    // Step 2-7: Same pipeline as processScan
    final fuzzyResults = _fuzzyMatcher!.matchAll(extractedRaw);
    final resolvedIngredients = extractedRaw.map((token) {
      final match = fuzzyResults[token];
      return match?.matched ?? token;
    }).toList();

    final ingredientRisks = <IngredientRiskProfile>[];
    for (final name in resolvedIngredients) {
      final profile = RiskRuleEngine.lookupIngredient(
        _ingredientMaster!,
        name,
      );
      if (profile != null) {
        ingredientRisks.add(profile);
      }
    }

    final overallRisk = RiskRuleEngine.computeProductRisk(
      resolvedIngredients,
      _ingredientMaster!,
    );

    final ingredientModels = await IngredientDataService.parseIngredientsFromText(
      resolvedIngredients.join(', '),
    );

    final alternatives = AlternativeEngine.getAlternatives(
      productCategory: productCategory,
      ingredientNames: resolvedIngredients,
    );

    final warnings = WarningEngine.generateWarnings(
      ingredients: ingredientModels,
      healthProfile: healthProfile,
    );

    return AnalysisResult(
      extractedIngredients: extractedRaw,
      resolvedIngredients: resolvedIngredients,
      ingredientRisks: ingredientRisks,
      overallRiskLevel: overallRisk,
      alternatives: alternatives,
      warnings: warnings,
      ingredientModels: ingredientModels,
      fuzzyMatches: fuzzyResults,
    );
  }

  // ── Accessors ─────────────────────────────────────────────────────────────

  /// Returns the full Ingredient Master Collection.
  static List<IngredientRiskProfile> get ingredientMaster {
    _ensureInitialised();
    return List.unmodifiable(_ingredientMaster!);
  }

  /// Returns the top N highest-risk ingredients.
  static List<IngredientRiskProfile> getTopHighRiskIngredients({int count = 10}) {
    _ensureInitialised();
    return RiskRuleEngine.getTopHighRisk(_ingredientMaster!, count: count);
  }

  /// Fuzzy-match a single ingredient name.
  static FuzzyMatchResult? fuzzyMatch(String input) {
    _ensureInitialised();
    return _fuzzyMatcher!.match(input);
  }

  /// Check if the service is initialised.
  static bool get isInitialised => _isInitialised;

  // ── Firestore Sync ────────────────────────────────────────────────────────

  /// Seed the `ingredients_master` collection in Firestore with the computed
  /// risk profiles.
  static Future<void> seedIngredientMasterToFirestore() async {
    _ensureInitialised();

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      for (final profile in _ingredientMaster!) {
        final docId = profile.name.toLowerCase().replaceAll(' ', '_');
        final ref = db.collection('ingredients_master').doc(docId);
        batch.set(ref, {
          ...profile.toFirestoreMap(),
          'seeded_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint(
        '[IngresafeAnalysisService] Seeded ${_ingredientMaster!.length} '
        'ingredients to Firestore ingredients_master collection.',
      );
    } catch (e) {
      debugPrint('[IngresafeAnalysisService] Firestore seed failed: $e');
    }
  }

  // ── Private ───────────────────────────────────────────────────────────────

  static void _ensureInitialised() {
    if (!_isInitialised) {
      debugPrint(
        '[IngresafeAnalysisService] WARNING: Service not initialised. '
        'Using fallback.',
      );
      _initializeFallback();
    }
  }
}
