import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ingresafe/models/ingredient_model.dart';
import 'package:ingresafe/models/scan_result.dart';
import '../utils/ocr_service.dart';

// ---------------------------------------------------------------------------
// 🔬 Ingredient knowledge base (replaces Firestore for offline MVP)
// ---------------------------------------------------------------------------
const _kIngredientDb = <String, Map<String, dynamic>>{
  'sugar': {
    'risk': 'Caution',
    'description': 'High sugar can cause blood-sugar spikes.',
    'explanation':
        'Sugar is a simple carbohydrate added to many processed foods. Excess consumption is linked to obesity, diabetes, and dental problems.',
    'regulatory':
        'Permitted in food but WHO recommends limiting free sugars to <10% of total energy intake.',
    'allergenKey': null,
    'conditionKey': 'Diabetes',
  },
  'high fructose corn syrup': {
    'risk': 'Risky',
    'description': 'Highly processed sweetener linked to metabolic disorders.',
    'explanation':
        'High-fructose corn syrup (HFCS) is metabolized primarily by the liver and is strongly associated with non-alcoholic fatty liver disease, insulin resistance, and obesity.',
    'regulatory':
        'Legal in most countries but heavily debated. Many health systems advise minimizing intake.',
    'allergenKey': null,
    'conditionKey': 'Diabetes',
  },
  'milk': {
    'risk': 'Caution',
    'description': 'Contains lactose and dairy proteins.',
    'explanation':
        'Milk is a common allergen and may trigger symptoms in people with lactose intolerance or dairy allergy.',
    'regulatory': 'Must be declared as a major allergen on product labels.',
    'allergenKey': 'Dairy',
    'conditionKey': 'Lactose Intolerance',
  },
  'milk solids': {
    'risk': 'Caution',
    'description': 'Concentrated dairy — contains lactose and casein.',
    'explanation':
        'Milk solids retain all the proteins and sugars of liquid milk, making them a potent trigger for people with dairy allergy or lactose intolerance.',
    'regulatory': 'Must be declared as a major allergen on product labels.',
    'allergenKey': 'Dairy',
    'conditionKey': 'Lactose Intolerance',
  },
  'lactose': {
    'risk': 'Caution',
    'description': 'Milk sugar — problematic for lactose intolerant users.',
    'explanation':
        'Lactose is the primary sugar in milk. People lacking the lactase enzyme experience bloating, cramps, and diarrhea after consumption.',
    'regulatory': 'Must be declared when dairy is a major allergen.',
    'allergenKey': 'Dairy',
    'conditionKey': 'Lactose Intolerance',
  },
  'gluten': {
    'risk': 'Risky',
    'description':
        'Wheat protein — triggers celiac disease and gluten sensitivity.',
    'explanation':
        'Gluten causes an autoimmune reaction in people with celiac disease, damaging the small intestine. Even trace amounts can be harmful.',
    'regulatory':
        'Products must label gluten-containing grains. "Gluten-Free" certification requires <20 ppm.',
    'allergenKey': 'Gluten',
    'conditionKey': null,
  },
  'wheat': {
    'risk': 'Caution',
    'description':
        'Contains gluten — avoid if you have celiac or wheat allergy.',
    'explanation':
        'Wheat is one of the top 9 major food allergens and is the primary source of gluten in the diet.',
    'regulatory': 'Must be declared as a major allergen.',
    'allergenKey': 'Gluten',
    'conditionKey': null,
  },
  'soy': {
    'risk': 'Caution',
    'description': 'Common plant-based allergen.',
    'explanation':
        'Soy is among the top 9 allergens. Symptoms range from mild hives to severe anaphylaxis in sensitive individuals.',
    'regulatory': 'Must be declared as a major allergen.',
    'allergenKey': 'Soy',
    'conditionKey': null,
  },
  'egg': {
    'risk': 'Caution',
    'description': 'Egg protein — common allergen, especially in children.',
    'explanation':
        'Egg allergy is one of the most common food allergies. Both egg white and yolk proteins can trigger reactions.',
    'regulatory': 'Must be declared as a major allergen.',
    'allergenKey': 'Egg',
    'conditionKey': null,
  },
  'nuts': {
    'risk': 'Risky',
    'description': 'Tree nuts — serious allergen, risk of anaphylaxis.',
    'explanation':
        'Tree nut allergies are lifelong for most people and can cause severe systemic reactions even from trace exposure.',
    'regulatory':
        'Must be prominently declared. Cross-contact warnings required.',
    'allergenKey': 'Nuts',
    'conditionKey': null,
  },
  'peanut': {
    'risk': 'Risky',
    'description': 'Peanuts — one of the most severe allergens.',
    'explanation':
        'Peanut allergy affects approximately 1–3% of the population. Reactions can be life-threatening and often persist into adulthood.',
    'regulatory':
        'Must be declared as a major allergen. Facilities must disclose cross-contact.',
    'allergenKey': 'Nuts',
    'conditionKey': null,
  },
  'shellfish': {
    'risk': 'Risky',
    'description': 'Shellfish — common trigger for severe allergic reactions.',
    'explanation':
        'Shellfish allergy is a lifelong condition in most adults. Tropomyosin is the key protein responsible for most reactions.',
    'regulatory': 'Must be declared as a major allergen.',
    'allergenKey': 'Shellfish',
    'conditionKey': null,
  },
  'sodium': {
    'risk': 'Caution',
    'description': 'High sodium contributes to hypertension.',
    'explanation':
        'Excess dietary sodium raises blood pressure, increasing the risk of heart disease and stroke. Processed foods are a major source.',
    'regulatory': 'WHO recommends <2g sodium (<5g salt) per day for adults.',
    'allergenKey': null,
    'conditionKey': 'High Blood Pressure',
  },
  'salt': {
    'risk': 'Caution',
    'description': 'High salt intake is linked to hypertension.',
    'explanation':
        'Salt is ~40% sodium. Regular high intake is one of the leading causes of elevated blood pressure and cardiovascular disease.',
    'regulatory': 'WHO recommends limiting daily intake to 5g of salt.',
    'allergenKey': null,
    'conditionKey': 'High Blood Pressure',
  },
  'saturated fat': {
    'risk': 'Caution',
    'description': 'Linked to elevated LDL and heart disease risk.',
    'explanation':
        'Saturated fats raise LDL (bad) cholesterol. Regular excess consumption is associated with increased cardiovascular risk.',
    'regulatory':
        'Dietary guidelines recommend saturated fat <10% of total daily calories.',
    'allergenKey': null,
    'conditionKey': 'Heart Condition',
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
  },
  'msg': {
    'risk': 'Caution',
    'description':
        'Monosodium glutamate — flavor enhancer; sensitivity varies.',
    'explanation':
        'MSG is a widely used flavor enhancer. While generally recognized as safe (GRAS), some individuals report sensitivity symptoms like headaches and flushing.',
    'regulatory':
        'Approved by FDA; must be listed on ingredient labels in most countries.',
    'allergenKey': null,
    'conditionKey': null,
  },
  'e621': {
    'risk': 'Risky',
    'description': 'E621 (MSG) — additive linked to sensitivity reactions.',
    'explanation':
        'E621 is the European code for monosodium glutamate. Despite being approved, there are ongoing debates about its effects at high doses.',
    'regulatory':
        'Approved for use in the EU with quantity limits in certain product categories.',
    'allergenKey': null,
    'conditionKey': null,
  },
  'e102': {
    'risk': 'Risky',
    'description':
        'Tartrazine (Yellow #5) — artificial colorant; may cause hyperactivity.',
    'explanation':
        'E102 is an azo dye linked to hyperactivity in children. It was part of the "Southampton six" colors that triggered UK regulatory concern.',
    'regulatory':
        'EU requires warning label: "may have an adverse effect on activity and attention in children." Banned in Norway and Austria.',
    'allergenKey': 'Artificial Colors',
    'conditionKey': null,
  },
  'artificial color': {
    'risk': 'Caution',
    'description':
        'Synthetic dyes — may trigger sensitivity in some individuals.',
    'explanation':
        'Artificial food colors are linked to behavioral effects in children and may cause allergic reactions in sensitive individuals.',
    'regulatory':
        'Approved for use but several require warning labels in the EU. Use under ongoing review.',
    'allergenKey': 'Artificial Colors',
    'conditionKey': null,
  },
  'preservative': {
    'risk': 'Caution',
    'description':
        'Chemical preservatives may cause reactions in sensitive individuals.',
    'explanation':
        'Preservatives such as benzoates, sulfites, and nitrites are used to extend shelf life. Some have been linked to allergic reactions and may affect gut microbiome.',
    'regulatory': 'Regulated with maximum permitted levels in most countries.',
    'allergenKey': null,
    'conditionKey': null,
  },
  'cocoa butter': {
    'risk': 'Safe',
    'description': 'Natural fat from cocoa beans — generally well tolerated.',
    'explanation':
        'Cocoa butter is a natural fat composed mostly of stearic acid and oleic acid. It has a neutral effect on blood cholesterol.',
    'regulatory':
        'No regulatory restrictions. Recognized as a natural food-grade fat.',
    'allergenKey': null,
    'conditionKey': null,
  },
  'lecithin': {
    'risk': 'Safe',
    'description': 'Natural emulsifier — soy or sunflower derived.',
    'explanation':
        'Lecithin is a phospholipid used as an emulsifier. It is generally recognized as safe (GRAS) and used in very small quantities.',
    'regulatory':
        'Approved globally. Highly refined soy lecithin is unlikely to trigger soy allergy.',
    'allergenKey': null,
    'conditionKey': null,
  },
  'vitamin c': {
    'risk': 'Safe',
    'description': 'Ascorbic acid — antioxidant, essential vitamin.',
    'explanation':
        'Vitamin C (ascorbic acid) is an essential nutrient and antioxidant. When used as an additive (E300), it also acts as a natural preservative.',
    'regulatory': 'Recognized as safe worldwide. No regulatory restrictions.',
    'allergenKey': null,
    'conditionKey': null,
  },
};

// ---------------------------------------------------------------------------
// ScanProvider
// ---------------------------------------------------------------------------
class ScanProvider with ChangeNotifier {
  File? _image;
  String _extractedText = '';
  bool _isProcessing = false;
  ScanResult? _currentScan;
  String? _errorMessage;

  final List<ScanResult> _recentScans = [];

  File? get image => _image;
  String get extractedText => _extractedText;
  bool get isProcessing => _isProcessing;
  ScanResult? get currentScan => _currentScan;
  String? get errorMessage => _errorMessage;
  List<ScanResult> get recentScans => List.unmodifiable(_recentScans);

  final OcrService _ocrService = OcrService();

  // ---------------------------------------------------------------------------
  // Main pipeline
  // ---------------------------------------------------------------------------
  Future<void> processImage(File imageFile) async {
    try {
      _image = imageFile;
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();

      final text = await _ocrService.extractTextFromImage(imageFile);
      _extractedText = text;

      final result = _buildScanResult(text);
      _currentScan = result;
      _recentScans.insert(0, result);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Scan error: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Build scan result from OCR text
  // ---------------------------------------------------------------------------
  ScanResult _buildScanResult(String text) {
    final ingredients = _parseIngredients(text);

    // Overall risk: worst of all ingredients
    String overallRisk = 'Safe';
    for (final ing in ingredients) {
      if (ing.riskLevel == 'Risky') {
        overallRisk = 'Risky';
        break;
      }
      if (ing.riskLevel == 'Caution') overallRisk = 'Caution';
    }

    return ScanResult(
      productName: _extractProductName(text),
      extractedText: text,
      riskLevel: overallRisk,
      scannedAt: DateTime.now(),
      ingredients: ingredients,
      warnings: _buildWarnings(ingredients),
    );
  }

  // ---------------------------------------------------------------------------
  // Parse raw text → list of IngredientModel
  // ---------------------------------------------------------------------------
  List<IngredientModel> _parseIngredients(String text) {
    final results = <IngredientModel>[];
    final lower = text.toLowerCase();

    // Check each known ingredient key against the extracted text
    for (final entry in _kIngredientDb.entries) {
      if (lower.contains(entry.key)) {
        final data = entry.value;
        results.add(
          IngredientModel(
            name: _capitalize(entry.key),
            riskLevel: data['risk'] as String,
            description: data['description'] as String,
            detailedExplanation: data['explanation'] as String,
            userImpact: _buildUserImpact(data),
            regulatoryNote: data['regulatory'] as String,
            allergenKey: data['allergenKey'] as String?,
            conditionKey: data['conditionKey'] as String?,
          ),
        );
      }
    }

    // If nothing was found, add a generic "unknown" ingredient
    if (results.isEmpty && text.isNotEmpty) {
      results.add(
        IngredientModel(
          name: 'Unknown Ingredients',
          riskLevel: 'Caution',
          description:
              'Could not identify individual ingredients from the label.',
          detailedExplanation:
              'The OCR scan captured text but could not match any known ingredients. Try scanning in better lighting or from a clearer angle.',
          userImpact:
              'No personalized risk assessment possible for unrecognized ingredients.',
          regulatoryNote:
              'Always consult the original product label for accurate ingredient information.',
        ),
      );
    }

    return results;
  }

  String _buildUserImpact(Map<String, dynamic> data) {
    final allergen = data['allergenKey'] as String?;
    final condition = data['conditionKey'] as String?;
    if (allergen != null && condition != null) {
      return 'Relevant if you have a $allergen allergy or $condition.';
    } else if (allergen != null) {
      return 'Relevant if you have a $allergen allergy.';
    } else if (condition != null) {
      return 'Relevant if you have $condition.';
    }
    return 'Check with your healthcare provider if you have specific dietary restrictions.';
  }

  List<String> _buildWarnings(List<IngredientModel> ingredients) {
    return ingredients
        .where((i) => i.riskLevel == 'Risky' || i.riskLevel == 'Caution')
        .map((i) => '${i.name}: ${i.description}')
        .toList();
  }

  String _extractProductName(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    return lines.isNotEmpty ? lines.first : 'Scanned Product';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  void clearScans() {
    _recentScans.clear();
    _currentScan = null;
    notifyListeners();
  }

  void disposeService() {
    _ocrService.dispose();
  }
}
