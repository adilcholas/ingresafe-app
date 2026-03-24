import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ingresafe/data/services/ingredient_data_service.dart';
import 'package:ingresafe/models/scan_result.dart';
import 'package:ingresafe/providers/scan_provider.dart';
import 'package:provider/provider.dart';

import '../utils/theme_constants.dart';

class CompareScreen extends StatefulWidget {
  /// The scan passed via route extra (preferred). Falls back to latest scan.
  final ScanResult? scan;

  const CompareScreen({super.key, this.scan});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  AlternativeProduct? _bestAlternative;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlternative();
  }

  Future<void> _loadAlternative() async {
    final scanResult =
        widget.scan ?? context.read<ScanProvider>().recentScans.firstOrNull;

    if (scanResult == null) {
      setState(() => _loading = false);
      return;
    }

    final alts = await IngredientDataService.getAlternatives(
      scanResult.ingredients,
    );

    if (mounted) {
      setState(() {
        _bestAlternative = alts.isNotEmpty ? alts.first : null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanResult =
        widget.scan ?? context.read<ScanProvider>().recentScans.firstOrNull;

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

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compare Ingredients')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final alternative = _bestAlternative ??
        const AlternativeProduct(
          name: 'Clean Ingredient Product',
          safety: 'Safe',
          reason: 'Minimal processed ingredients — clean label',
          tags: ['Clean Label'],
        );

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
                    icon: Icons.qr_code_scanner,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Icon(Icons.compare_arrows, size: 28),
                      SizedBox(height: 4),
                      Text(
                        'VS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _CompareCard(
                    title: 'Better Alternative',
                    productName: alternative.name,
                    risk: alternative.safety,
                    color: AppColors.safe,
                    icon: Icons.verified_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// ── AI Insight ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      alternative.reason,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// ── Ingredient Comparison Table Header ──────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ingredient Comparison (${scanResult.ingredients.length} detected)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            /// ── Column Headers ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: const [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Ingredient',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Scanned',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Alternative',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.safe,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),
            const SizedBox(height: 8),

            Expanded(child: _buildComparisonTable(scanResult)),

            const SizedBox(height: 12),

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No ingredients to compare.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: scanResult.ingredients.length,
      itemBuilder: (context, index) {
        final ing = scanResult.ingredients[index];
        final isSafe = ing.riskLevel == 'Safe';
        final originalValue = ing.riskLevel;
        final alternativeValue = isSafe ? 'Safe' : 'Reduced / Absent';

        return _ComparisonRow(
          label: ing.name,
          original: originalValue,
          alternative: alternativeValue,
          isBetter: isSafe,
          description: ing.description,
        );
      },
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
  final IconData icon;

  const _CompareCard({
    required this.title,
    required this.productName,
    required this.risk,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.04),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            productName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
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
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
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
  final String description;

  const _ComparisonRow({
    required this.label,
    required this.original,
    required this.alternative,
    required this.isBetter,
    required this.description,
  });

  Color _originalColor() {
    switch (original) {
      case 'Safe':
        return AppColors.safe;
      case 'Risky':
        return AppColors.danger;
      default:
        return AppColors.caution;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _originalColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  original,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _originalColor(),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isBetter ? Icons.check_circle : Icons.swap_horiz,
                    color: AppColors.safe,
                    size: 14,
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      alternative,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.safe,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
