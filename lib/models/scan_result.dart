import 'package:cloud_firestore/cloud_firestore.dart';
import 'ingredient_model.dart';

class ScanResult {
  final String? firestoreId; // null until persisted
  final String? userId; // The ID of the user who owns this scan
  final String productName;
  final String extractedText;
  final String riskLevel;
  final DateTime scannedAt;
  final List<IngredientModel> ingredients;
  final List<String> warnings;

  ScanResult({
    this.firestoreId,
    this.userId,
    required this.productName,
    required this.extractedText,
    required this.riskLevel,
    required this.scannedAt,
    this.ingredients = const [],
    this.warnings = const [],
  });

  ScanResult copyWith({String? firestoreId, String? userId}) => ScanResult(
        firestoreId: firestoreId ?? this.firestoreId,
        userId: userId ?? this.userId,
        productName: productName,
        extractedText: extractedText,
        riskLevel: riskLevel,
        scannedAt: scannedAt,
        ingredients: ingredients,
        warnings: warnings,
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'productName': productName,
        'extractedText': extractedText,
        'riskLevel': riskLevel,
        'scannedAt': Timestamp.fromDate(scannedAt),
        'ingredients': ingredients.map((i) => i.toMap()).toList(),
        'warnings': warnings,
      };

  factory ScanResult.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['scannedAt'];
    DateTime scannedAt;
    if (ts is Timestamp) {
      scannedAt = ts.toDate();
    } else {
      scannedAt = DateTime.tryParse(ts?.toString() ?? '') ?? DateTime.now();
    }

    final rawIngredients = map['ingredients'] as List<dynamic>? ?? [];
    final ingredients = rawIngredients
        .map((e) => IngredientModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return ScanResult(
      firestoreId: id,
      userId: map['userId'] as String?,
      productName: map['productName'] as String? ?? 'Unknown Product',
      extractedText: map['extractedText'] as String? ?? '',
      riskLevel: map['riskLevel'] as String? ?? 'Caution',
      scannedAt: scannedAt,
      ingredients: ingredients,
      warnings: List<String>.from(map['warnings'] as List? ?? []),
    );
  }
}
