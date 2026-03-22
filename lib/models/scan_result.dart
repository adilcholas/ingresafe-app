class ScanResult {
  final String productName;
  final String extractedText;
  final String riskLevel;
  final DateTime scannedAt;

  ScanResult({
    required this.productName,
    required this.extractedText,
    required this.riskLevel,
    required this.scannedAt,
  });
}