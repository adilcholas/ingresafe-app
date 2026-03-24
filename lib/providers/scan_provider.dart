import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ingresafe/data/services/ingredient_data_service.dart';
import 'package:ingresafe/data/services/scan_history_service.dart';
import 'package:ingresafe/models/ingredient_model.dart';
import 'package:ingresafe/models/scan_result.dart';
import '../utils/ocr_service.dart';

// ---------------------------------------------------------------------------
// ScanProvider
// ---------------------------------------------------------------------------
class ScanProvider with ChangeNotifier {
  File? _image;
  String _extractedText = '';
  bool _isProcessing = false;
  bool _isLoadingHistory = false;
  ScanResult? _currentScan;
  String? _errorMessage;
  bool _isSeeded = false;

  final List<ScanResult> _recentScans = [];

  File? get image => _image;
  String get extractedText => _extractedText;
  bool get isProcessing => _isProcessing;
  bool get isLoadingHistory => _isLoadingHistory;
  ScanResult? get currentScan => _currentScan;
  String? get errorMessage => _errorMessage;
  List<ScanResult> get recentScans => List.unmodifiable(_recentScans);

  final OcrService _ocrService = OcrService();

  String? _userId;

  ScanProvider();

  void updateUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    
    if (_userId == null) {
      _recentScans.clear();
      _currentScan = null;
      notifyListeners();
    } else {
      reloadHistory();
    }
  }

  // ---------------------------------------------------------------------------
  // Seed Firestore with ingredient + alternatives database
  // ---------------------------------------------------------------------------
  Future<void> seedFirestoreIfNeeded() async {
    if (_isSeeded) return;
    _isSeeded = true;
    await IngredientDataService.seedFirestore();
  }

  // ---------------------------------------------------------------------------
  // Main pipeline — real OCR scan
  // ---------------------------------------------------------------------------
  Future<void> processImage(File imageFile) async {
    try {
      _image = imageFile;
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();

      // Ensure Firestore data is seeded
      await seedFirestoreIfNeeded();

      final text = await _ocrService.extractTextFromImage(imageFile);
      _extractedText = text;

      final result = await _buildScanResult(text);
      final resultWithUser = result.copyWith(userId: _userId);

      // Persist to Firestore and get back the doc-ID-enriched result
      final saved = await ScanHistoryService.saveScan(resultWithUser);
      _currentScan = saved;
      _recentScans.insert(0, saved);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Scan error: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Demo scan — loads rich test data without needing a real image
  // ---------------------------------------------------------------------------
  Future<void> loadDemoScan() async {
    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();

      // Simulate processing delay for UX
      await Future.delayed(const Duration(milliseconds: 800));

      final ingredients = IngredientDataService.getDemoIngredients();

      String overallRisk = 'Safe';
      for (final ing in ingredients) {
        if (ing.riskLevel == 'Risky') {
          overallRisk = 'Risky';
          break;
        }
        if (ing.riskLevel == 'Caution') overallRisk = 'Caution';
      }

      final result = ScanResult(
        userId: _userId,
        productName: 'Demo Cookie Biscuit — Chocolate Cream',
        extractedText:
            'Ingredients: Sugar, High Fructose Corn Syrup, Wheat Flour, '
            'Palm Oil, Milk Solids, Cocoa Powder, Sodium Benzoate, '
            'Artificial Color, Lecithin, Vitamin C',
        riskLevel: overallRisk,
        scannedAt: DateTime.now(),
        ingredients: ingredients,
        warnings: ingredients
            .where((i) => i.riskLevel == 'Risky' || i.riskLevel == 'Caution')
            .map((i) => '${i.name}: ${i.description}')
            .toList(),
      );

      // Persist to Firestore
      final saved = await ScanHistoryService.saveScan(result);
      _currentScan = saved;
      _recentScans.insert(0, saved);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Demo scan error: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Build scan result from OCR text (Firestore-backed ingredient service)
  // ---------------------------------------------------------------------------
  Future<ScanResult> _buildScanResult(String text) async {
    final ingredients = await IngredientDataService.parseIngredientsFromText(text);

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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Reloads scan history from Firestore (e.g. after deleting a single entry).
  Future<void> reloadHistory() async {
    if (_userId == null) return;
    
    _isLoadingHistory = true;
    notifyListeners();

    final history = await ScanHistoryService.loadHistory(_userId!);
    _recentScans
      ..clear()
      ..addAll(history);

    _isLoadingHistory = false;
    notifyListeners();
  }

  /// Clears local list and removes all Firestore history for the current user.
  Future<void> clearScans() async {
    if (_userId == null) return;
    
    _recentScans.clear();
    _currentScan = null;
    notifyListeners();
    await ScanHistoryService.clearHistory(_userId!);
  }

  void disposeService() {
    _ocrService.dispose();
  }
}
