import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/scan_provider.dart';
import '../utils/theme_constants.dart';

class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scanProvider = context.watch<ScanProvider>();

    final scan = scanProvider.recentScans.isNotEmpty
        ? scanProvider.recentScans.first
        : null;

    if (scan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Compare Ingredients")),
        body: const Center(
          child: Text(
            "No scan available to compare.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final alternative = _getAlternative(scan.extractedText);

    return Scaffold(
      appBar: AppBar(title: const Text("Compare Ingredients")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// Product vs Alternative
            Row(
              children: [
                Expanded(
                  child: _CompareCard(
                    title: "Scanned Product",
                    productName: scan.productName,
                    risk: scan.riskLevel,
                    color: _getRiskColor(scan.riskLevel),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.compare_arrows),
                const SizedBox(width: 12),
                Expanded(
                  child: _CompareCard(
                    title: "Better Alternative",
                    productName: alternative.name,
                    risk: alternative.safety,
                    color: alternative.color,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// Insight Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: const [
                  Icon(Icons.auto_awesome, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "The alternative has fewer harmful ingredients and aligns better with your health profile.",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// Ingredient Breakdown
            Expanded(
              child: ListView(
                children: [
                  _ComparisonRow(
                    label: "Artificial Additives",
                    original: "Present",
                    alternative: "Absent",
                    isBetter: true,
                  ),
                  _ComparisonRow(
                    label: "Sugar Level",
                    original: "High",
                    alternative: "Reduced",
                    isBetter: true,
                  ),
                  _ComparisonRow(
                    label: "Allergen Risk",
                    original: "Medium",
                    alternative: "Low",
                    isBetter: true,
                  ),
                ],
              ),
            ),

            /// Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text("Done"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dummy alternative (aligned with previous logic)
  _Alt _getAlternative(String text) {
    final lower = text.toLowerCase();

    if (lower.contains("sugar")) {
      return _Alt(
        name: "Low Sugar Organic Spread",
        safety: "Better",
        color: AppColors.caution,
      );
    }

    if (lower.contains("milk")) {
      return _Alt(
        name: "Dairy-Free Vegan Spread",
        safety: "Safer",
        color: AppColors.safe,
      );
    }

    return _Alt(
      name: "Clean Ingredient Product",
      safety: "Safe",
      color: AppColors.safe,
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'Safe':
        return AppColors.safe;
      case 'Caution':
        return AppColors.caution;
      case 'Risky':
        return AppColors.danger;
      default:
        return Colors.grey;
    }
  }
}

/// Compare Card
class _CompareCard extends StatelessWidget {
  final String title;
  final String productName;
  final String risk;
  final Color color;

  const _CompareCard({
    required this.title,
    required this.productName,
    required this.risk,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(productName, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              risk,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Comparison Row
class _ComparisonRow extends StatelessWidget {
  final String label;
  final String original;
  final String alternative;
  final bool isBetter;

  const _ComparisonRow({
    required this.label,
    required this.original,
    required this.alternative,
    required this.isBetter,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(original, style: const TextStyle(color: Colors.red)),
          Text(alternative, style: const TextStyle(color: Colors.green)),
        ],
      ),
      trailing: Icon(
        isBetter ? Icons.check_circle : Icons.warning,
        color: isBetter ? Colors.green : Colors.orange,
      ),
    );
  }
}

/// Internal model
class _Alt {
  final String name;
  final String safety;
  final Color color;

  _Alt({required this.name, required this.safety, required this.color});
}
