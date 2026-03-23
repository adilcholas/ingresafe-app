import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ingresafe/models/scan_result.dart';
import 'package:ingresafe/providers/scan_provider.dart';
import 'package:provider/provider.dart';

import '../utils/theme_constants.dart';

class CompareScreen extends StatelessWidget {
  /// The scan passed via route extra (preferred). Falls back to latest scan.
  final ScanResult? scan;

  const CompareScreen({super.key, this.scan});

  @override
  Widget build(BuildContext context) {
    final scanResult =
        scan ?? context.read<ScanProvider>().recentScans.firstOrNull;

    if (scanResult == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compare Ingredients')),
        body: const Center(
          child: Text(
            'No scan available to compare.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final alternative = _getBestAlternative(scanResult);

    return Scaffold(
      appBar: AppBar(title: const Text('Compare Ingredients')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// ── Product vs Alternative ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _CompareCard(
                    title: 'Scanned Product',
                    productName: scanResult.productName,
                    risk: scanResult.riskLevel,
                    color: _riskColor(scanResult.riskLevel),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.compare_arrows, size: 28),
                ),
                Expanded(
                  child: _CompareCard(
                    title: 'Better Alternative',
                    productName: alternative.name,
                    risk: alternative.safety,
                    color: alternative.color,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// ── AI Insight ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: const [
                  Icon(Icons.auto_awesome, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The alternative has fewer harmful ingredients and aligns better with your health profile.',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// ── Ingredient Comparison Table ─────────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ingredient Comparison (${scanResult.ingredients.length} detected)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(child: _buildComparisonTable(scanResult)),

            /// ── Done Button ─────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable(ScanResult scanResult) {
    if (scanResult.ingredients.isEmpty) {
      return const Center(
        child: Text(
          'No ingredients to compare.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: scanResult.ingredients.length,
      itemBuilder: (context, index) {
        final ing = scanResult.ingredients[index];
        final isBetter = ing.riskLevel == 'Safe';
        final originalValue = ing.riskLevel;
        final alternativeValue = isBetter ? 'Safe' : 'Reduced / Absent';

        return _ComparisonRow(
          label: ing.name,
          original: originalValue,
          alternative: alternativeValue,
          isBetter: isBetter,
        );
      },
    );
  }

  _Alt _getBestAlternative(ScanResult result) {
    final names = result.ingredients.map((i) => i.name.toLowerCase()).toSet();

    if (names.any((n) => n.contains('milk') || n.contains('lactose'))) {
      return _Alt(
        name: 'Dairy-Free Vegan Alternative',
        safety: 'Safer',
        color: AppColors.safe,
      );
    }
    if (names.any((n) => n.contains('sugar') || n.contains('fructose'))) {
      return _Alt(
        name: 'Low Sugar Organic Option',
        safety: 'Better',
        color: AppColors.caution,
      );
    }
    if (names.any((n) => n.contains('gluten') || n.contains('wheat'))) {
      return _Alt(
        name: 'Gluten-Free Alternative',
        safety: 'Safe',
        color: AppColors.safe,
      );
    }
    return _Alt(
      name: 'Clean Ingredient Product',
      safety: 'Safe',
      color: AppColors.safe,
    );
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'Safe':
        return AppColors.safe;
      case 'Risky':
        return AppColors.danger;
      default:
        return AppColors.caution;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
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
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            productName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
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

// ─────────────────────────────────────────────────────────────────────────────
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
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            original,
            style: TextStyle(
              color: isBetter ? AppColors.safe : AppColors.danger,
            ),
          ),
          Text(alternative, style: const TextStyle(color: AppColors.safe)),
        ],
      ),
      trailing: Icon(
        isBetter ? Icons.check_circle : Icons.swap_horiz,
        color: isBetter ? AppColors.safe : AppColors.caution,
      ),
    );
  }
}

class _Alt {
  final String name;
  final String safety;
  final Color color;

  _Alt({required this.name, required this.safety, required this.color});
}
