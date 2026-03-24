import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/ingredient_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Local fallback dataset – mirrors what is seeded to Firestore
// ─────────────────────────────────────────────────────────────────────────────
const _kLocalIngredients = <String, Map<String, dynamic>>{
  'sugar': {
    'risk': 'Caution',
    'description': 'High sugar can cause blood-sugar spikes.',
    'explanation':
        'Sugar is a simple carbohydrate added to many processed foods. Excess consumption is linked to obesity, diabetes, and dental problems.',
    'regulatory':
        'Permitted in food but WHO recommends limiting free sugars to <10% of total energy intake.',
    'allergenKey': null,
    'conditionKey': 'Diabetes',
    'category': 'Sweetener',
  },
  'high fructose corn syrup': {
    'risk': 'Risky',
    'description': 'Highly processed sweetener linked to metabolic disorders.',
    'explanation':
        'HFCS is metabolized primarily by the liver and strongly associated with non-alcoholic fatty liver disease, insulin resistance, and obesity.',
    'regulatory':
        'Legal in most countries but heavily debated. Many health systems advise minimizing intake.',
    'allergenKey': null,
    'conditionKey': 'Diabetes',
    'category': 'Sweetener',
  },
  'milk': {
    'risk': 'Caution',
    'description': 'Contains lactose and dairy proteins.',
    'explanation':
        'Milk is a common allergen and may trigger symptoms in people with lactose intolerance or dairy allergy.',
    'regulatory': 'Must be declared as a major allergen on product labels.',
    'allergenKey': 'Dairy',
    'conditionKey': 'Lactose Intolerance',
    'category': 'Dairy',
  },
  'milk solids': {
    'risk': 'Caution',
    'description': 'Concentrated dairy — contains lactose and casein.',
    'explanation':
        'Milk solids retain all proteins and sugars of liquid milk, making them a potent trigger for people with dairy allergy or lactose intolerance.',
    'regulatory': 'Must be declared as a major allergen on product labels.',
    'allergenKey': 'Dairy',
    'conditionKey': 'Lactose Intolerance',
    'category': 'Dairy',
  },
  'skim milk': {
    'risk': 'Caution',
    'description': 'Low-fat milk — still contains lactose and dairy proteins.',
    'explanation':
        'Skim milk retains all dairy proteins including casein and whey. Problematic for dairy-allergic and lactose-intolerant users.',
    'regulatory': 'Must be declared as a major allergen.',
    'allergenKey': 'Dairy',
    'conditionKey': 'Lactose Intolerance',
    'category': 'Dairy',
  },
  'lactose': {
    'risk': 'Caution',
    'description': 'Milk sugar — problematic for lactose intolerant users.',
    'explanation':
        'Lactose is the primary sugar in milk. People lacking the lactase enzyme experience bloating, cramps, and diarrhea after consumption.',
    'regulatory': 'Must be declared when dairy is a major allergen.',
    'allergenKey': 'Dairy',
    'conditionKey': 'Lactose Intolerance',
    'category': 'Dairy',
  },
  'gluten': {
    'risk': 'Risky',
    'description': 'Wheat protein — triggers celiac disease and gluten sensitivity.',
    'explanation':
        'Gluten causes an autoimmune reaction in people with celiac disease, damaging the small intestine. Even trace amounts can be harmful.',
    'regulatory':
        'Products must label gluten-containing grains. "Gluten-Free" certification requires <20 ppm.',
    'allergenKey': 'Gluten',
    'conditionKey': null,
    'category': 'Allergen',
  },
  'wheat': {
    'risk': 'Caution',
    'description': 'Contains gluten — avoid if you have celiac or wheat allergy.',
    'explanation':
        'Wheat is one of the top 9 major food allergens and is the primary source of gluten in the diet.',
    'regulatory': 'Must be declared as a major allergen.',
    'allergenKey': 'Gluten',
    'conditionKey': null,
    'category': 'Allergen',
  },
  'wheat flour': {
    'risk': 'Caution',
    'description': 'All-purpose wheat flour — contains gluten.',
    'explanation':
        'Wheat flour is a staple ingredient containing significant amounts of gluten. Unsuitable for celiac disease or wheat allergy sufferers.',
    'regulatory': 'Must be declared as a major allergen.',
    'allergenKey': 'Gluten',
    'conditionKey': null,
    'category': 'Grain',
  },
  'soy': {
    'risk': 'Caution',
    'description': 'Common plant-based allergen.',
    'explanation':
        'Soy is among the top 9 allergens. Symptoms range from mild hives to severe anaphylaxis in sensitive individuals.',
    'regulatory': 'Must be declared as a major allergen.',
    'allergenKey': 'Soy',
    'conditionKey': null,
    'category': 'Allergen',
  },
  'soybean oil': {
    'risk': 'Safe',
    'description': 'Refined soybean oil — generally safe even for soy-allergic individuals.',
    'explanation':
        'Highly refined soybean oil has most soy proteins removed. The FDA exempts it from soy allergen labeling, though unrefined versions should be avoided.',
    'regulatory': 'Exempt from soy allergen labeling in the US when highly refined.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Oil',
  },
  'egg': {
    'risk': 'Caution',
    'description': 'Egg protein — common allergen, especially in children.',
    'explanation':
        'Egg allergy is one of the most common food allergies. Both egg white and yolk proteins can trigger reactions.',
    'regulatory': 'Must be declared as a major allergen.',
    'allergenKey': 'Egg',
    'conditionKey': null,
    'category': 'Allergen',
  },
  'nuts': {
    'risk': 'Risky',
    'description': 'Tree nuts — serious allergen, risk of anaphylaxis.',
    'explanation':
        'Tree nut allergies are lifelong for most people and can cause severe systemic reactions even from trace exposure.',
    'regulatory': 'Must be prominently declared. Cross-contact warnings required.',
    'allergenKey': 'Nuts',
    'conditionKey': null,
    'category': 'Allergen',
  },
  'peanut': {
    'risk': 'Risky',
    'description': 'Peanuts — one of the most severe allergens.',
    'explanation':
        'Peanut allergy affects approximately 1–3% of the population. Reactions can be life-threatening and often persist into adulthood.',
    'regulatory': 'Must be declared as a major allergen. Facilities must disclose cross-contact.',
    'allergenKey': 'Nuts',
    'conditionKey': null,
    'category': 'Allergen',
  },
  'shellfish': {
    'risk': 'Risky',
    'description': 'Shellfish — common trigger for severe allergic reactions.',
    'explanation':
        'Shellfish allergy is a lifelong condition in most adults. Tropomyosin is the key protein responsible for most reactions.',
    'regulatory': 'Must be declared as a major allergen.',
    'allergenKey': 'Shellfish',
    'conditionKey': null,
    'category': 'Allergen',
  },
  'sodium': {
    'risk': 'Caution',
    'description': 'High sodium contributes to hypertension.',
    'explanation':
        'Excess dietary sodium raises blood pressure, increasing the risk of heart disease and stroke. Processed foods are a major source.',
    'regulatory': 'WHO recommends <2g sodium (<5g salt) per day for adults.',
    'allergenKey': null,
    'conditionKey': 'High Blood Pressure',
    'category': 'Mineral',
  },
  'salt': {
    'risk': 'Caution',
    'description': 'High salt intake is linked to hypertension.',
    'explanation':
        'Salt is ~40% sodium. Regular high intake is one of the leading causes of elevated blood pressure and cardiovascular disease.',
    'regulatory': 'WHO recommends limiting daily intake to 5g of salt.',
    'allergenKey': null,
    'conditionKey': 'High Blood Pressure',
    'category': 'Mineral',
  },
  'saturated fat': {
    'risk': 'Caution',
    'description': 'Linked to elevated LDL and heart disease risk.',
    'explanation':
        'Saturated fats raise LDL (bad) cholesterol. Regular excess consumption is associated with increased cardiovascular risk.',
    'regulatory': 'Dietary guidelines recommend saturated fat <10% of total daily calories.',
    'allergenKey': null,
    'conditionKey': 'Heart Condition',
    'category': 'Fat',
  },
  'palm oil': {
    'risk': 'Caution',
    'description': 'High in saturated fat — moderate cardiovascular concern.',
    'explanation':
        'Palm oil contains ~50% saturated fat. Regular consumption may elevate LDL cholesterol levels, though it also contains beneficial vitamin E.',
    'regulatory': 'Requires declaration on food labels. Environmental concerns documented.',
    'allergenKey': null,
    'conditionKey': 'Heart Condition',
    'category': 'Fat',
  },
  'trans fat': {
    'risk': 'Risky',
    'description': 'Artificial trans fats — the most harmful dietary fat.',
    'explanation':
        'Industrial trans fats raise LDL and lower HDL cholesterol simultaneously, dramatically increasing the risk of heart disease.',
    'regulatory':
        'Banned or severely restricted in many countries. WHO calls for global elimination from food supply.',
    'allergenKey': null,
    'conditionKey': 'Heart Condition',
    'category': 'Fat',
  },
  'partially hydrogenated oil': {
    'risk': 'Risky',
    'description': 'Major source of artificial trans fats.',
    'explanation':
        'Partial hydrogenation creates trans fatty acids that are strongly linked to heart disease. The FDA has revoked GRAS status for partially hydrogenated oils.',
    'regulatory': 'Effectively banned in the US, EU, and many other countries.',
    'allergenKey': null,
    'conditionKey': 'Heart Condition',
    'category': 'Fat',
  },
  'msg': {
    'risk': 'Caution',
    'description': 'Monosodium glutamate — flavor enhancer; sensitivity varies.',
    'explanation':
        'MSG is a widely used flavor enhancer. While generally recognized as safe (GRAS), some individuals report sensitivity symptoms like headaches and flushing.',
    'regulatory': 'Approved by FDA; must be listed on ingredient labels in most countries.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Additive',
  },
  'e621': {
    'risk': 'Risky',
    'description': 'E621 (MSG) — additive linked to sensitivity reactions.',
    'explanation':
        'E621 is the European code for monosodium glutamate. Despite being approved, there are ongoing debates about its effects at high doses.',
    'regulatory': 'Approved for use in the EU with quantity limits in certain product categories.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Additive',
  },
  'e102': {
    'risk': 'Risky',
    'description': 'Tartrazine (Yellow #5) — artificial colorant; may cause hyperactivity.',
    'explanation':
        'E102 is an azo dye linked to hyperactivity in children. It was part of the "Southampton six" colors that triggered UK regulatory concern.',
    'regulatory':
        'EU requires warning label: "may have an adverse effect on activity and attention in children." Banned in Norway and Austria.',
    'allergenKey': 'Artificial Colors',
    'conditionKey': null,
    'category': 'Colorant',
  },
  'artificial color': {
    'risk': 'Caution',
    'description': 'Synthetic dyes — may trigger sensitivity in some individuals.',
    'explanation':
        'Artificial food colors are linked to behavioral effects in children and may cause allergic reactions in sensitive individuals.',
    'regulatory': 'Approved for use but several require warning labels in the EU. Use under ongoing review.',
    'allergenKey': 'Artificial Colors',
    'conditionKey': null,
    'category': 'Colorant',
  },
  'artificial flavour': {
    'risk': 'Caution',
    'description': 'Synthetic flavor compounds — may cause sensitivities.',
    'explanation':
        'Artificial flavors are chemically synthesized flavor compounds. Most are safe at approved levels, but some individuals report sensitivities.',
    'regulatory': 'Must be listed on labels. Specific compounds require approval in each market.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Flavoring',
  },
  'preservative': {
    'risk': 'Caution',
    'description': 'Chemical preservatives may cause reactions in sensitive individuals.',
    'explanation':
        'Preservatives such as benzoates, sulfites, and nitrites are used to extend shelf life. Some have been linked to allergic reactions and may affect gut microbiome.',
    'regulatory': 'Regulated with maximum permitted levels in most countries.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Preservative',
  },
  'sodium benzoate': {
    'risk': 'Caution',
    'description': 'Common preservative — potential carcinogen risk with vitamin C.',
    'explanation':
        'Sodium benzoate can form benzene (a known carcinogen) when combined with ascorbic acid (vitamin C) in acidic conditions. Linked to hyperactivity in children.',
    'regulatory': 'Approved globally with concentration limits. Requires declaration on labels.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Preservative',
  },
  'potassium sorbate': {
    'risk': 'Safe',
    'description': 'Mild preservative — generally recognized as safe.',
    'explanation':
        'Potassium sorbate inhibits mold and yeast growth. It is one of the most widely used and safest preservatives in the food industry.',
    'regulatory': 'GRAS status in the US. Approved in the EU and globally.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Preservative',
  },
  'cocoa butter': {
    'risk': 'Safe',
    'description': 'Natural fat from cocoa beans — generally well tolerated.',
    'explanation':
        'Cocoa butter is a natural fat composed mostly of stearic acid and oleic acid. It has a neutral effect on blood cholesterol.',
    'regulatory': 'No regulatory restrictions. Recognized as a natural food-grade fat.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Fat',
  },
  'cocoa powder': {
    'risk': 'Safe',
    'description': 'Antioxidant-rich cocoa solids.',
    'explanation':
        'Cocoa powder is rich in flavonoids and antioxidants. Associated with cardiovascular benefits. Contains small amounts of caffeine.',
    'regulatory': 'Natural food ingredient with no regulatory restrictions.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Natural',
  },
  'lecithin': {
    'risk': 'Safe',
    'description': 'Natural emulsifier — soy or sunflower derived.',
    'explanation':
        'Lecithin is a phospholipid used as an emulsifier. It is generally recognized as safe (GRAS) and used in very small quantities.',
    'regulatory': 'Approved globally. Highly refined soy lecithin is unlikely to trigger soy allergy.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Emulsifier',
  },
  'sunflower oil': {
    'risk': 'Safe',
    'description': 'Healthy vegetable oil rich in vitamin E.',
    'explanation':
        'Sunflower oil is high in unsaturated fats and vitamin E. When not overheated, it is a heart-healthy cooking oil.',
    'regulatory': 'Natural food ingredient with no regulatory restrictions.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Oil',
  },
  'vitamin c': {
    'risk': 'Safe',
    'description': 'Ascorbic acid — antioxidant, essential vitamin.',
    'explanation':
        'Vitamin C (ascorbic acid) is an essential nutrient and antioxidant. When used as an additive (E300), it also acts as a natural preservative.',
    'regulatory': 'Recognized as safe worldwide. No regulatory restrictions.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Vitamin',
  },
  'vitamin e': {
    'risk': 'Safe',
    'description': 'Tocopherol — fat-soluble antioxidant.',
    'explanation':
        'Vitamin E protects cells from oxidative stress. As a food additive (E306-309), it prevents rancidity in oils and fats.',
    'regulatory': 'Recognized as safe worldwide. No regulatory restrictions.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Vitamin',
  },
  'calcium carbonate': {
    'risk': 'Safe',
    'description': 'Mineral supplement and anti-caking agent.',
    'explanation':
        'Calcium carbonate is a natural source of calcium used to supplement food and prevent clumping. Safe at approved levels.',
    'regulatory': 'Recognized as safe globally.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Mineral',
  },
  'natural flavour': {
    'risk': 'Safe',
    'description': 'Flavoring derived from natural sources.',
    'explanation':
        'Natural flavors are derived from plant or animal sources. Generally considered safer than artificial alternatives. Exact compounds vary.',
    'regulatory': 'Must be listed on labels. Sources must be natural per regulatory definition.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Flavoring',
  },
  'water': {
    'risk': 'Safe',
    'description': 'Purified water — safe for all consumers.',
    'explanation': 'Water is added to maintain product consistency and moisture. Has no health concerns.',
    'regulatory': 'No restrictions.',
    'allergenKey': null,
    'conditionKey': null,
    'category': 'Base',
  },
};

// ─────────────────────────────────────────────────────────────────────────────
// Safer Alternatives Dataset
// ─────────────────────────────────────────────────────────────────────────────
const _kAlternativesDb = <String, List<Map<String, dynamic>>>{
  'Sweetener': [
    {
      'name': 'Low Sugar Organic Spread',
      'safety': 'Better Choice',
      'reason': 'Significantly reduced sugar content with natural sweeteners',
      'tags': ['Low Sugar', 'Organic'],
    },
    {
      'name': 'Stevia-Sweetened Alternative',
      'safety': 'Highly Safe',
      'reason': 'Zero glycemic impact — uses plant-based stevia sweetener',
      'tags': ['Zero Sugar', 'Plant-Based'],
    },
  ],
  'Dairy': [
    {
      'name': 'Vegan Dairy-Free Spread',
      'safety': 'Safer',
      'reason': 'No dairy ingredients — ideal for lactose intolerance and dairy allergy',
      'tags': ['Dairy-Free', 'Vegan'],
    },
    {
      'name': 'Oat Milk Alternative',
      'safety': 'Plant-Based',
      'reason': 'Made from oats — free from dairy proteins and lactose',
      'tags': ['Oat-Based', 'Vegan'],
    },
  ],
  'Allergen': [
    {
      'name': 'Gluten-Free Certified Alternative',
      'safety': 'Safe for Celiac',
      'reason': 'Certified gluten-free — safe for celiac disease and wheat allergy',
      'tags': ['Gluten-Free', 'Certified'],
    },
    {
      'name': 'Nut-Free Organic Option',
      'safety': 'Allergen Safe',
      'reason': 'Produced in a dedicated nut-free facility',
      'tags': ['Nut-Free', 'Allergen-Safe'],
    },
  ],
  'Fat': [
    {
      'name': 'Heart-Healthy Olive Oil Spread',
      'safety': 'Heart Safe',
      'reason': 'No trans fats — high in monounsaturated healthy fats',
      'tags': ['Heart-Safe', 'No Trans Fat'],
    },
    {
      'name': 'Avocado Oil Blend',
      'safety': 'Clean Label',
      'reason': 'Rich in oleic acid — promotes healthy cholesterol levels',
      'tags': ['Clean Label', 'Heart-Healthy'],
    },
  ],
  'Additive': [
    {
      'name': 'Organic Clean-Label Spread',
      'safety': 'Highly Safe',
      'reason': 'No artificial additives, MSG, or flavor enhancers',
      'tags': ['No Additives', 'Organic'],
    },
  ],
  'Colorant': [
    {
      'name': 'Natural Color Organic Product',
      'safety': 'Natural',
      'reason': 'Uses only plant-derived natural colorants — no synthetic dyes',
      'tags': ['Natural Colors', 'No Artificial Dyes'],
    },
  ],
  'Preservative': [
    {
      'name': 'Preservative-Free Organic Spread',
      'safety': 'Clean Label',
      'reason': 'No chemical preservatives — naturally preserved or vacuum packed',
      'tags': ['Preservative-Free', 'Clean Label'],
    },
  ],
};

/// Alternative product model
class AlternativeProduct {
  final String name;
  final String safety;
  final String reason;
  final List<String> tags;

  const AlternativeProduct({
    required this.name,
    required this.safety,
    required this.reason,
    required this.tags,
  });

  factory AlternativeProduct.fromMap(Map<String, dynamic> map) {
    return AlternativeProduct(
      name: map['name'] as String,
      safety: map['safety'] as String,
      reason: map['reason'] as String,
      tags: List<String>.from(map['tags'] as List),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'safety': safety,
    'reason': reason,
    'tags': tags,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// IngredientDataService
// ─────────────────────────────────────────────────────────────────────────────

class IngredientDataService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Seed Firestore ──────────────────────────────────────────────────────────

  /// Seeds ingredients and alternatives to Firestore.
  /// Safe to call multiple times (uses set with merge).
  static Future<void> seedFirestore() async {
    try {
      debugPrint('[IngredientDataService] Starting Firestore seed...');
      final batch = _db.batch();

      // Seed ingredients
      for (final entry in _kLocalIngredients.entries) {
        final ref = _db.collection('ingredients').doc(entry.key.replaceAll(' ', '_'));
        batch.set(ref, {
          'normalized_name': entry.key,
          ...entry.value,
          'seeded_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('[IngredientDataService] Ingredients seeded (${_kLocalIngredients.length} items).');

      // Seed alternatives (separate batch)
      final altBatch = _db.batch();
      for (final entry in _kAlternativesDb.entries) {
        for (int i = 0; i < entry.value.length; i++) {
          final ref = _db.collection('alternatives').doc('${entry.key}_$i');
          altBatch.set(ref, {
            'category': entry.key,
            ...entry.value[i],
            'seeded_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      await altBatch.commit();
      debugPrint('[IngredientDataService] Alternatives seeded.');
    } catch (e) {
      debugPrint('[IngredientDataService] Seed error: $e');
    }
  }

  // ── Ingredient Lookup ───────────────────────────────────────────────────────

  /// Returns ingredient data from Firestore, falling back to local dataset.
  static Future<Map<String, dynamic>?> lookupIngredient(String normalizedKey) async {
    // 1. Try local first (fast, offline-safe)
    if (_kLocalIngredients.containsKey(normalizedKey)) {
      return _kLocalIngredients[normalizedKey];
    }

    // 2. Try Firestore
    try {
      final snap = await _db
          .collection('ingredients')
          .where('normalized_name', isEqualTo: normalizedKey)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) return snap.docs.first.data();
    } catch (e) {
      debugPrint('[IngredientDataService] Firestore lookup failed: $e');
    }

    return null;
  }

  // ── Parse text → IngredientModel list ──────────────────────────────────────

  /// Scans OCR text against the full ingredient database and returns matches.
  static Future<List<IngredientModel>> parseIngredientsFromText(String text) async {
    final results = <IngredientModel>[];
    final lower = text.toLowerCase();

    // Sort keys by length descending so multi-word phrases match first
    final sortedKeys = _kLocalIngredients.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final key in sortedKeys) {
      if (lower.contains(key)) {
        final data = _kLocalIngredients[key]!;
        results.add(_buildModel(key, data));
      }
    }

    // Firestore supplementary lookup for unknown tokens
    if (results.isEmpty && text.isNotEmpty) {
      try {
        final tokens = lower
            .split(RegExp(r'[,;\n\r]'))
            .map((t) => t.trim())
            .where((t) => t.length > 2)
            .take(20)
            .toList();

        for (final token in tokens) {
          final data = await lookupIngredient(token);
          if (data != null) {
            results.add(_buildModel(token, data));
          }
        }
      } catch (e) {
        debugPrint('[IngredientDataService] Supplementary lookup failed: $e');
      }
    }

    // Generic fallback
    if (results.isEmpty && text.isNotEmpty) {
      results.add(IngredientModel(
        name: 'Unknown Ingredients',
        riskLevel: 'Caution',
        description: 'Could not identify individual ingredients from the label.',
        detailedExplanation:
            'The OCR scan captured text but could not match any known ingredients. Try scanning in better lighting or from a clearer angle.',
        userImpact:
            'No personalized risk assessment possible for unrecognized ingredients.',
        regulatoryNote:
            'Always consult the original product label for accurate ingredient information.',
      ));
    }

    return results;
  }

  // ── Alternatives Lookup ─────────────────────────────────────────────────────

  /// Returns safer alternatives based on ingredient categories detected in the scan.
  static Future<List<AlternativeProduct>> getAlternatives(
    List<IngredientModel> ingredients,
  ) async {
    final results = <AlternativeProduct>[];
    final addedNames = <String>{};

    // Determine which categories are in the ingredient list
    final categories = <String>{};
    for (final ing in ingredients) {
      if (ing.riskLevel == 'Safe') continue;
      final cat = _getCategoryForIngredient(ing.name.toLowerCase());
      if (cat != null) categories.add(cat);
    }

    // 1. Try Firestore alternatives first
    try {
      for (final category in categories) {
        final snap = await _db
            .collection('alternatives')
            .where('category', isEqualTo: category)
            .limit(2)
            .get();

        for (final doc in snap.docs) {
          final alt = AlternativeProduct.fromMap(doc.data());
          if (!addedNames.contains(alt.name)) {
            results.add(alt);
            addedNames.add(alt.name);
          }
        }
      }
    } catch (e) {
      debugPrint('[IngredientDataService] Alternatives Firestore query failed: $e');
    }

    // 2. Fill from local dataset if Firestore returned nothing
    if (results.isEmpty) {
      for (final category in categories) {
        final localAlts = _kAlternativesDb[category] ?? [];
        for (final altMap in localAlts) {
          final alt = AlternativeProduct.fromMap(altMap);
          if (!addedNames.contains(alt.name)) {
            results.add(alt);
            addedNames.add(alt.name);
          }
        }
      }
    }

    // 3. Generic fallback
    if (results.isEmpty) {
      results.add(const AlternativeProduct(
        name: 'Natural Ingredient Product',
        safety: 'Safe',
        reason: 'Minimal processed ingredients — clean label with no harmful additives',
        tags: ['Clean Label', 'Natural'],
      ));
    }

    return results;
  }

  // ── Demo Scan Dataset ───────────────────────────────────────────────────────

  /// Returns a rich demo scan ScanResult-like dataset for testing all features.
  static List<IngredientModel> getDemoIngredients() {
    final demoKeys = [
      'sugar',
      'high fructose corn syrup',
      'milk solids',
      'wheat flour',
      'palm oil',
      'sodium benzoate',
      'artificial color',
      'cocoa powder',
      'lecithin',
      'vitamin c',
    ];

    return demoKeys.map((key) {
      final data = _kLocalIngredients[key]!;
      return _buildModel(key, data);
    }).toList();
  }

  // ── Private Helpers ─────────────────────────────────────────────────────────

  static IngredientModel _buildModel(String key, Map<String, dynamic> data) {
    final allergen = data['allergenKey'] as String?;
    final condition = data['conditionKey'] as String?;
    String userImpact;
    if (allergen != null && condition != null) {
      userImpact = 'Relevant if you have a $allergen allergy or $condition.';
    } else if (allergen != null) {
      userImpact = 'Relevant if you have a $allergen allergy.';
    } else if (condition != null) {
      userImpact = 'Relevant if you have $condition.';
    } else {
      userImpact = 'Check with your healthcare provider if you have specific dietary restrictions.';
    }

    return IngredientModel(
      name: _capitalize(key),
      riskLevel: data['risk'] as String,
      description: data['description'] as String,
      detailedExplanation: data['explanation'] as String,
      userImpact: userImpact,
      regulatoryNote: data['regulatory'] as String,
      allergenKey: allergen,
      conditionKey: condition,
    );
  }

  static String? _getCategoryForIngredient(String name) {
    for (final entry in _kLocalIngredients.entries) {
      if (name.contains(entry.key) || entry.key.contains(name)) {
        return entry.value['category'] as String?;
      }
    }
    return null;
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }
}
