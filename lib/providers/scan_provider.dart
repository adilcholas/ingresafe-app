import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ingresafe/models/scan_result.dart';
import '../utils/ocr_service.dart';

class ScanProvider with ChangeNotifier {
  File? _image;
  String _extractedText = "";
  bool _isProcessing = false;

  /// 🔥 NEW: store recent scans
  final List<ScanResult> _recentScans = [];

  File? get image => _image;
  String get extractedText => _extractedText;
  bool get isProcessing => _isProcessing;
  List<ScanResult> get recentScans => List.unmodifiable(_recentScans);

  final OcrService _ocrService = OcrService();

  /// 🔥 MAIN PIPELINE
  Future<void> processImage(File imageFile) async {
    try {
      _image = imageFile;
      _isProcessing = true;
      notifyListeners();

      final text = await _ocrService.extractTextFromImage(imageFile);
      _extractedText = text;

      /// 🔥 Basic parsing (MVP)
      final result = _buildScanResult(text);

      /// 🔥 Save to recent (latest on top)
      _recentScans.insert(0, result);
    } catch (e) {
      debugPrint("Scan error: $e");
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// 🔥 MVP parser (you will improve this later)
  ScanResult _buildScanResult(String text) {
    final lower = text.toLowerCase();

    String risk = "Safe";

    if (lower.contains("preservative") ||
        lower.contains("artificial") ||
        lower.contains("msg")) {
      risk = "Caution";
    }

    if (lower.contains("e621") ||
        lower.contains("e102") ||
        lower.contains("high fructose")) {
      risk = "Risky";
    }

    return ScanResult(
      productName: _extractProductName(text),
      extractedText: text,
      riskLevel: risk,
      scannedAt: DateTime.now(),
    );
  }

  /// 🔥 Simple product name extractor (placeholder)
  String _extractProductName(String text) {
    final lines = text.split('\n');
    return lines.isNotEmpty ? lines.first : "Unknown Product";
  }

  /// Optional: clear history
  void clearScans() {
    _recentScans.clear();
    notifyListeners();
  }

  void disposeService() {
    _ocrService.dispose();
  }
}
