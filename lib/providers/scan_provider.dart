import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/ocr_service.dart';

class ScanProvider with ChangeNotifier {
  File? _image;
  String _extractedText = "";
  bool _isProcessing = false;

  File? get image => _image;
  String get extractedText => _extractedText;
  bool get isProcessing => _isProcessing;

  final OcrService _ocrService = OcrService();

  Future<void> processImage(File imageFile) async {
    _image = imageFile;
    _isProcessing = true;
    notifyListeners();

    final text = await _ocrService.extractTextFromImage(imageFile);
    _extractedText = text;

    _isProcessing = false;
    notifyListeners();
  }

  void disposeService() {
    _ocrService.dispose();
  }
}