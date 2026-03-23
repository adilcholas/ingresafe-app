import 'ingredient_model.dart';

class ScanResult {
  final String productName;
  final String extractedText;
  final String riskLevel;
  final DateTime scannedAt;
  final List<IngredientModel> ingredients;
  final List<String> warnings;

  ScanResult({
    required this.productName,
    required this.extractedText,
    required this.riskLevel,
    required this.scannedAt,
    this.ingredients = const [],
    this.warnings = const [],
  });
}
