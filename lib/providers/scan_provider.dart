import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ingresafe/data/services/ingredient_data_service.dart';
import 'package:ingresafe/data/services/ingresafe_analysis_service.dart';
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

  /// Stores the last full analysis result for downstream screens
  AnalysisResult? _lastAnalysis;

  final List<ScanResult> _recentScans = [];

  File? get image => _image;
  String get extractedText => _extractedText;
  bool get isProcessing => _isProcessing;
  bool get isLoadingHistory => _isLoadingHistory;
  ScanResult? get currentScan => _currentScan;
  String? get errorMessage => _errorMessage;
  List<ScanResult> get recentScans => List.unmodifiable(_recentScans);

  /// Access the full analysis result (ingredients, fuzzy matches, alternatives, etc.)
  AnalysisResult? get lastAnalysis => _lastAnalysis;

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
  // Main pipeline — real OCR scan (uses new analysis service)
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
  // Build scan result using the full analysis pipeline:
  //   1. IngredientParser   → zero-loss extraction (Issue #1)
  //   2. FuzzyMatcher       → resolve misspellings  (Issue #4)
  //   3. RiskRuleEngine     → per-ingredient risk    (Issue #2)
  //   4. AlternativeEngine  → category-aware alts    (Issue #3)
  //   5. WarningEngine      → personalised warnings
  // ---------------------------------------------------------------------------
  Future<ScanResult> _buildScanResult(String text) async {
    // Run the full analysis pipeline
    final analysis = await IngresafeAnalysisService.processScan(
      ocrText: text,
      productCategory: 'Food', // Default; can be enhanced with category detection
    );

    // Store for downstream screens (alternatives, compare, etc.)
    _lastAnalysis = analysis;

    // Map overall risk level from the new engine's output to the existing
    // ScanResult risk level format (Safe/Caution/Risky)
    final overallRisk = _mapRiskLevel(analysis.overallRiskLevel);

    // Use the ingredient models from the analysis, which are enriched with
    // fuzzy-matched names and full risk data
    final ingredients = analysis.ingredientModels;

    // Build warnings that include fuzzy match corrections
    final warnings = _buildWarnings(ingredients, analysis);

    return ScanResult(
      productName: _extractProductName(text),
      extractedText: text,
      riskLevel: overallRisk,
      scannedAt: DateTime.now(),
      ingredients: ingredients,
      warnings: warnings,
    );
  }

  List<String> _buildWarnings(
    List<IngredientModel> ingredients,
    AnalysisResult analysis,
  ) {
    final warnings = <String>[];

    // Add ingredient-level warnings
    for (final ing in ingredients) {
      if (ing.riskLevel == 'Risky' || ing.riskLevel == 'Caution') {
        warnings.add('${ing.name}: ${ing.description}');
      }
    }

    // Add fuzzy match corrections as informational warnings
    for (final entry in analysis.fuzzyMatches.entries) {
      final match = entry.value;
      if (match != null && !match.isExactMatch) {
        warnings.add(
          '📝 Auto-corrected: "${entry.key}" → "${match.matched}" '
          '(${(match.similarity * 100).toStringAsFixed(0)}% match)',
        );
      }
    }

    return warnings;
  }

  /// Maps the RiskRuleEngine's "High"/"Medium"/"Low" to the existing
  /// ScanResult format of "Risky"/"Caution"/"Safe"
  String _mapRiskLevel(String engineLevel) {
    switch (engineLevel) {
      case 'High':
        return 'Risky';
      case 'Medium':
        return 'Caution';
      default:
        return 'Safe';
    }
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

