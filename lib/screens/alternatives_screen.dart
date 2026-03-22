import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/scan_provider.dart';
import '../utils/theme_constants.dart';
import '../widgets/common/alternative_product_card.dart';

class AlternativesScreen extends StatelessWidget {
  const AlternativesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scanProvider = context.watch<ScanProvider>();

    /// Get latest scan
    final latestScan = scanProvider.recentScans.isNotEmpty
        ? scanProvider.recentScans.first
        : null;

    final alternatives = latestScan != null
        ? _generateAlternatives(latestScan.extractedText)
        : [];

    return Scaffold(
      appBar: AppBar(title: const Text("Safer Alternatives")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: latestScan == null
            ? const Center(
                child: Text(
                  "No scan data available.\nScan a product first.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Header Insight Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.auto_awesome,
                          color: AppColors.primary,
                          size: 30,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "AI suggested alternatives based on your scan results.",
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Recommended Safer Products",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  /// Alternatives List
                  Expanded(
                    child: ListView.builder(
                      itemCount: alternatives.length,
                      itemBuilder: (context, index) {
                        final item = alternatives[index];
                        return AlternativeProductCard(
                          productName: item.name,
                          safetyLevel: item.safety,
                          reason: item.reason,
                          riskColor: item.color,
                        );
                      },
                    ),
                  ),

                  /// Compare Button (now working)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.push('/compare', extra: latestScan);
                      },
                      child: const Text("Compare Ingredients"),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// 🔥 MVP dynamic alternatives generator
  List<_AlternativeItem> _generateAlternatives(String text) {
    final lower = text.toLowerCase();

    final List<_AlternativeItem> results = [];

    if (lower.contains("sugar")) {
      results.add(
        _AlternativeItem(
          name: "Low Sugar Organic Spread",
          safety: "Better Choice",
          reason: "Reduced sugar content",
          color: AppColors.caution,
        ),
      );
    }

    if (lower.contains("milk") || lower.contains("lactose")) {
      results.add(
        _AlternativeItem(
          name: "Vegan Dairy-Free Spread",
          safety: "Safer",
          reason: "No dairy ingredients",
          color: AppColors.safe,
        ),
      );
    }

    if (lower.contains("preservative") ||
        lower.contains("artificial") ||
        lower.contains("e")) {
      results.add(
        _AlternativeItem(
          name: "Organic Clean-Label Spread",
          safety: "Highly Safe",
          reason: "No artificial additives",
          color: AppColors.safe,
        ),
      );
    }

    /// fallback
    if (results.isEmpty) {
      results.add(
        _AlternativeItem(
          name: "Natural Ingredient Product",
          safety: "Safe",
          reason: "Minimal processed ingredients",
          color: AppColors.safe,
        ),
      );
    }

    return results;
  }
}

/// Internal model (lightweight)
class _AlternativeItem {
  final String name;
  final String safety;
  final String reason;
  final Color color;

  _AlternativeItem({
    required this.name,
    required this.safety,
    required this.reason,
    required this.color,
  });
}
