/// ─────────────────────────────────────────────────────────────────────────────
/// Ingresafe – Alternative Recommendation Engine
/// ─────────────────────────────────────────────────────────────────────────────
///
/// Solves Issue #3: **Alternative Recommendation Logic**
///
/// Uses both the `category` field and the `ingredients` list to suggest healthy
/// alternatives. The logic:
///
///   1. Identify which harmful ingredients are in the scanned product.
///   2. Map each harmful ingredient to its "ingredient category" (Sweetener,
///      Preservative, Fat, Additive, etc.) using the existing
///      `_kLocalIngredients` database.
///   3. Cross-reference with the product's `category` (Beverage, Snack, etc.)
///      to provide **category-specific** alternative suggestions.
///   4. If a category-specific alternative is not available, fall back to
///      generic alternatives for that ingredient type.
///
/// Example flow:
///   Product: "Energy Drink" (category: Beverage)
///   Contains: "High Fructose Corn Syrup" → Sweetener category
///   → Suggests: "Coconut Water" (Beverage + no harmful sweeteners)
/// ─────────────────────────────────────────────────────────────────────────────

import '../services/ingredient_data_service.dart';

/// A category-aware alternative recommendation.
class AlternativeRecommendation {
  final String productName;
  final String reason;
  final String safetyBadge;
  final List<String> tags;
  final String targetCategory;
  final List<String> replacesIngredients;

  const AlternativeRecommendation({
    required this.productName,
    required this.reason,
    required this.safetyBadge,
    required this.tags,
    required this.targetCategory,
    required this.replacesIngredients,
  });

  Map<String, dynamic> toMap() => {
    'productName': productName,
    'reason': reason,
    'safetyBadge': safetyBadge,
    'tags': tags,
    'targetCategory': targetCategory,
    'replacesIngredients': replacesIngredients,
  };
}

class AlternativeEngine {
  /// ── Get alternatives for a scanned product ─────────────────────────────────
  ///
  /// [productCategory] – e.g. "Beverage", "Snack", "Food", "Dairy", "Cosmetic"
  /// [ingredientNames]  – list of ingredient names found in the product
  ///
  /// Returns a deduplicated list of alternative recommendations, prioritising
  /// category-specific suggestions.
  static List<AlternativeRecommendation> getAlternatives({
    required String productCategory,
    required List<String> ingredientNames,
  }) {
    final results = <AlternativeRecommendation>[];
    final addedKeys = <String>{};

    // Step 1: Identify harmful ingredients and their categories
    final harmfulByCategory = <String, List<String>>{};

    for (final name in ingredientNames) {
      final key = name.toLowerCase().trim();
      final riskInfo = _kHarmfulIngredientCategories[key];
      if (riskInfo != null) {
        harmfulByCategory.putIfAbsent(riskInfo, () => []).add(name);
      }
    }

    // Step 2: Try category-specific alternatives first
    for (final entry in harmfulByCategory.entries) {
      final ingredientCategory = entry.key;
      final harmfulNames = entry.value;

      final categorySpecific = _kCategorySpecificAlternatives[productCategory];
      if (categorySpecific != null && categorySpecific.containsKey(ingredientCategory)) {
        for (final alt in categorySpecific[ingredientCategory]!) {
          final altKey = alt.productName.toLowerCase();
          if (!addedKeys.contains(altKey)) {
            results.add(AlternativeRecommendation(
              productName: alt.productName,
              reason: alt.reason,
              safetyBadge: alt.safetyBadge,
              tags: alt.tags,
              targetCategory: productCategory,
              replacesIngredients: harmfulNames,
            ));
            addedKeys.add(altKey);
          }
        }
      }
    }

    // Step 3: Fill with generic alternatives for categories not yet covered
    for (final entry in harmfulByCategory.entries) {
      final ingredientCategory = entry.key;
      final harmfulNames = entry.value;

      final genericAlts = _kGenericAlternatives[ingredientCategory];
      if (genericAlts != null) {
        for (final alt in genericAlts) {
          final altKey = alt.productName.toLowerCase();
          if (!addedKeys.contains(altKey)) {
            results.add(AlternativeRecommendation(
              productName: alt.productName,
              reason: alt.reason,
              safetyBadge: alt.safetyBadge,
              tags: alt.tags,
              targetCategory: productCategory,
              replacesIngredients: harmfulNames,
            ));
            addedKeys.add(altKey);
          }
        }
      }
    }

    // Step 4: Fallback
    if (results.isEmpty) {
      results.add(const AlternativeRecommendation(
        productName: 'Organic Clean-Label Product',
        reason: 'Choose products with minimal, recognisable ingredients',
        safetyBadge: 'Better Choice',
        tags: ['Clean Label', 'Organic'],
        targetCategory: 'General',
        replacesIngredients: [],
      ));
    }

    return results;
  }

  /// ── Async variant that also checks Firestore for alternatives ──────────────
  static Future<List<AlternativeRecommendation>> getAlternativesAsync({
    required String productCategory,
    required List<String> ingredientNames,
  }) async {
    // Start with local alternatives
    final localAlts = getAlternatives(
      productCategory: productCategory,
      ingredientNames: ingredientNames,
    );

    // Supplement with the existing IngredientDataService alternatives
    try {
      // Build IngredientModel list for the existing service
      final models = await IngredientDataService.parseIngredientsFromText(
        ingredientNames.join(', '),
      );
      final serviceAlts = await IngredientDataService.getAlternatives(models);

      final addedKeys = localAlts.map((a) => a.productName.toLowerCase()).toSet();

      for (final alt in serviceAlts) {
        if (!addedKeys.contains(alt.name.toLowerCase())) {
          localAlts.add(AlternativeRecommendation(
            productName: alt.name,
            reason: alt.reason,
            safetyBadge: alt.safety,
            tags: alt.tags,
            targetCategory: productCategory,
            replacesIngredients: [],
          ));
          addedKeys.add(alt.name.toLowerCase());
        }
      }
    } catch (_) {
      // Firestore unavailable; local results are sufficient
    }

    return localAlts;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ingredient → Category mapping for the 19 ingredients in our dataset
// ─────────────────────────────────────────────────────────────────────────────
const _kHarmfulIngredientCategories = <String, String>{
  // Harmful sweeteners
  'sugar': 'Sweetener',
  'high fructose corn syrup': 'Sweetener',

  // Harmful preservatives
  'sodium benzoate': 'Preservative',
  'potassium sorbate': 'Preservative',
  'parabens': 'Preservative',

  // Harmful fats
  'palm oil': 'Fat',

  // Harmful additives
  'msg': 'Additive',
  'sls': 'Additive',
  'propylene glycol': 'Additive',
  'artificial flavor': 'Flavoring',
  'fragrance': 'Cosmetic Additive',

  // Colorants
  'caramel color': 'Colorant',

  // Refined grains
  'refined flour': 'Grain',
};

// ─────────────────────────────────────────────────────────────────────────────
// Category-Specific Alternative Recommendations
// Map: ProductCategory → IngredientCategory → List<Alternative>
// ─────────────────────────────────────────────────────────────────────────────

class _AltEntry {
  final String productName;
  final String reason;
  final String safetyBadge;
  final List<String> tags;

  const _AltEntry({
    required this.productName,
    required this.reason,
    required this.safetyBadge,
    required this.tags,
  });
}

const _kCategorySpecificAlternatives = <String, Map<String, List<_AltEntry>>>{
  'Beverage': {
    'Sweetener': [
      _AltEntry(
        productName: 'Coconut Water',
        reason: 'Naturally sweet with electrolytes — no added sugars or HFCS',
        safetyBadge: 'Natural',
        tags: ['No Added Sugar', 'Electrolytes', 'Natural'],
      ),
      _AltEntry(
        productName: 'Kombucha (Low Sugar)',
        reason: 'Fermented tea with probiotics — minimal residual sugar',
        safetyBadge: 'Better Choice',
        tags: ['Probiotic', 'Low Sugar', 'Fermented'],
      ),
      _AltEntry(
        productName: 'Sparkling Water with Lemon',
        reason: 'Zero sugar, zero additives — naturally refreshing',
        safetyBadge: 'Highly Safe',
        tags: ['Zero Sugar', 'No Additives'],
      ),
    ],
    'Preservative': [
      _AltEntry(
        productName: 'Fresh-Pressed Juice',
        reason: 'Cold-pressed, no preservatives — consume within 3 days',
        safetyBadge: 'Natural',
        tags: ['Preservative-Free', 'Fresh'],
      ),
    ],
    'Colorant': [
      _AltEntry(
        productName: 'Herbal Iced Tea',
        reason: 'Naturally coloured from herbs — no artificial dyes',
        safetyBadge: 'Natural',
        tags: ['Natural Colors', 'Caffeine-Free'],
      ),
    ],
  },
  'Snack': {
    'Sweetener': [
      _AltEntry(
        productName: 'Date & Nut Energy Balls',
        reason: 'Sweetened only with whole dates — rich in fibre and minerals',
        safetyBadge: 'Natural',
        tags: ['Whole Food', 'No Added Sugar'],
      ),
      _AltEntry(
        productName: 'Dark Chocolate (85%+)',
        reason: 'Minimal sugar, high in antioxidant flavonoids',
        safetyBadge: 'Better Choice',
        tags: ['Low Sugar', 'Antioxidant'],
      ),
    ],
    'Fat': [
      _AltEntry(
        productName: 'Baked Veggie Chips',
        reason: 'Baked not fried — no palm oil, lower saturated fat',
        safetyBadge: 'Heart Safe',
        tags: ['Baked', 'No Palm Oil'],
      ),
      _AltEntry(
        productName: 'Air-Popped Popcorn',
        reason: 'Whole grain, minimal fat — season with herbs instead of salt',
        safetyBadge: 'Highly Safe',
        tags: ['Whole Grain', 'Low Fat'],
      ),
    ],
    'Additive': [
      _AltEntry(
        productName: 'Organic Trail Mix',
        reason: 'No MSG, no artificial additives — pure nuts, seeds, and dried fruit',
        safetyBadge: 'Clean Label',
        tags: ['No Additives', 'Organic'],
      ),
    ],
    'Grain': [
      _AltEntry(
        productName: 'Rice Crackers',
        reason: 'Made from whole grain rice — no refined flour or wheat',
        safetyBadge: 'Gluten-Free',
        tags: ['Gluten-Free', 'Whole Grain'],
      ),
    ],
  },
  'Food': {
    'Sweetener': [
      _AltEntry(
        productName: 'Stevia-Sweetened Spread',
        reason: 'Zero glycemic impact — suitable for diabetics',
        safetyBadge: 'Highly Safe',
        tags: ['Zero Sugar', 'Plant-Based'],
      ),
    ],
    'Fat': [
      _AltEntry(
        productName: 'Extra Virgin Olive Oil Products',
        reason: 'Rich in monounsaturated fats — no palm oil',
        safetyBadge: 'Heart Safe',
        tags: ['Heart-Healthy', 'No Palm Oil'],
      ),
    ],
    'Preservative': [
      _AltEntry(
        productName: 'Naturally Preserved Organic Foods',
        reason: 'Vacuum-sealed or naturally preserved — no benzoates or sorbates',
        safetyBadge: 'Clean Label',
        tags: ['Preservative-Free', 'Organic'],
      ),
    ],
    'Additive': [
      _AltEntry(
        productName: 'Clean Label Sauces & Seasonings',
        reason: 'No MSG, no artificial flavors — seasoned with herbs and spices',
        safetyBadge: 'Clean Label',
        tags: ['No MSG', 'Natural Flavoring'],
      ),
    ],
    'Grain': [
      _AltEntry(
        productName: 'Whole Wheat / Millet Flour Products',
        reason: 'Unrefined whole grain — retains fiber and nutrients',
        safetyBadge: 'Better Choice',
        tags: ['Whole Grain', 'High Fiber'],
      ),
    ],
  },
  'Dairy': {
    'Sweetener': [
      _AltEntry(
        productName: 'Plain Greek Yogurt',
        reason: 'High protein, no added sugar — sweeten naturally with fruit',
        safetyBadge: 'Natural',
        tags: ['No Added Sugar', 'High Protein'],
      ),
    ],
    'Preservative': [
      _AltEntry(
        productName: 'Fresh Farm Dairy Products',
        reason: 'Short shelf life, no preservatives — refrigeration-preserved',
        safetyBadge: 'Natural',
        tags: ['Preservative-Free', 'Fresh'],
      ),
    ],
    'Fat': [
      _AltEntry(
        productName: 'Oat Milk / Almond Milk',
        reason: 'Plant-based, no palm oil — low in saturated fat',
        safetyBadge: 'Plant-Based',
        tags: ['Dairy-Free', 'Low Saturated Fat'],
      ),
    ],
  },
  'Cosmetic': {
    'Additive': [
      _AltEntry(
        productName: 'SLS-Free Natural Soap',
        reason: 'Uses plant-derived surfactants instead of SLS/SLES',
        safetyBadge: 'Skin Safe',
        tags: ['SLS-Free', 'Natural'],
      ),
    ],
    'Cosmetic Additive': [
      _AltEntry(
        productName: 'Fragrance-Free Hypoallergenic Products',
        reason: 'No synthetic fragrances — suitable for sensitive skin',
        safetyBadge: 'Dermatologist Tested',
        tags: ['Fragrance-Free', 'Hypoallergenic'],
      ),
    ],
    'Preservative': [
      _AltEntry(
        productName: 'Paraben-Free Organic Skincare',
        reason: 'Preserved with natural alternatives like rosemary extract',
        safetyBadge: 'Clean Beauty',
        tags: ['Paraben-Free', 'Organic'],
      ),
    ],
  },
};

// ─────────────────────────────────────────────────────────────────────────────
// Generic (category-agnostic) alternatives as fallback
// ─────────────────────────────────────────────────────────────────────────────
const _kGenericAlternatives = <String, List<_AltEntry>>{
  'Sweetener': [
    _AltEntry(
      productName: 'Stevia-Sweetened Alternative',
      reason: 'Zero glycemic impact — uses plant-based stevia sweetener',
      safetyBadge: 'Highly Safe',
      tags: ['Zero Sugar', 'Plant-Based'],
    ),
    _AltEntry(
      productName: 'Date-Sweetened Products',
      reason: 'Natural whole fruit sweetener with fibre and minerals',
      safetyBadge: 'Natural',
      tags: ['Whole Food', 'No Refined Sugar'],
    ),
  ],
  'Preservative': [
    _AltEntry(
      productName: 'Preservative-Free Organic Options',
      reason: 'Naturally preserved or vacuum-packed for freshness',
      safetyBadge: 'Clean Label',
      tags: ['Preservative-Free', 'Clean Label'],
    ),
  ],
  'Fat': [
    _AltEntry(
      productName: 'Olive Oil / Avocado Oil Based Products',
      reason: 'Heart-healthy monounsaturated fats — no palm oil',
      safetyBadge: 'Heart Safe',
      tags: ['Heart-Healthy', 'No Palm Oil'],
    ),
  ],
  'Additive': [
    _AltEntry(
      productName: 'Clean Label Additive-Free Products',
      reason: 'No artificial additives, MSG, or chemical enhancers',
      safetyBadge: 'Clean Label',
      tags: ['No Additives', 'Natural'],
    ),
  ],
  'Flavoring': [
    _AltEntry(
      productName: 'Natural Flavour Products',
      reason: 'Uses only plant-derived natural flavourings',
      safetyBadge: 'Natural',
      tags: ['Natural Flavors', 'No Artificial'],
    ),
  ],
  'Cosmetic Additive': [
    _AltEntry(
      productName: 'Fragrance-Free Natural Products',
      reason: 'No synthetic fragrances — essential oils only',
      safetyBadge: 'Skin Safe',
      tags: ['Fragrance-Free', 'Natural'],
    ),
  ],
  'Colorant': [
    _AltEntry(
      productName: 'Naturally Coloured Products',
      reason: 'Coloured with beetroot, turmeric, or spirulina — no synthetic dyes',
      safetyBadge: 'Natural',
      tags: ['Natural Colors', 'No Artificial Dyes'],
    ),
  ],
  'Grain': [
    _AltEntry(
      productName: 'Whole Grain / Gluten-Free Options',
      reason: 'Unrefined whole grains or certified gluten-free alternatives',
      safetyBadge: 'Better Choice',
      tags: ['Whole Grain', 'High Fiber'],
    ),
  ],
};
