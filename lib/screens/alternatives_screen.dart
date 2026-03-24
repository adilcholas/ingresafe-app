import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ingresafe/data/services/ingredient_data_service.dart';
import 'package:ingresafe/models/scan_result.dart';
import 'package:ingresafe/providers/scan_provider.dart';
import 'package:provider/provider.dart';

import '../utils/theme_constants.dart';

class AlternativesScreen extends StatefulWidget {
  /// The scan passed via route extra (preferred). Falls back to latest scan.
  final ScanResult? scan;

  const AlternativesScreen({super.key, this.scan});

  @override
  State<AlternativesScreen> createState() => _AlternativesScreenState();
}

class _AlternativesScreenState extends State<AlternativesScreen> {
  List<AlternativeProduct>? _alternatives;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlternatives();
  }

  Future<void> _loadAlternatives() async {
    final scanResult =
        widget.scan ?? context.read<ScanProvider>().recentScans.firstOrNull;

    if (scanResult == null) {
      setState(() {
        _alternatives = [];
        _loading = false;
      });
      return;
    }

    final alts = await IngredientDataService.getAlternatives(
      scanResult.ingredients,
    );

    if (mounted) {
      setState(() {
        _alternatives = alts;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanResult =
        widget.scan ?? context.read<ScanProvider>().recentScans.firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Safer Alternatives')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: scanResult == null
            ? const Center(
                child: Text(
                  'No scan data available.\nScan a product first.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ── Header Insight Card ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: AppColors.primary,
                          size: 30,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI-suggested alternatives',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Based on ${scanResult.ingredients.length} detected ingredients',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Recommended Safer Products',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  /// ── Alternatives List ─────────────────────────────────────
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  'Finding safer alternatives...',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : (_alternatives == null || _alternatives!.isEmpty)
                            ? const Center(
                                child: Text(
                                  'No specific alternatives found.\nThis product appears to have safe ingredients.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _alternatives!.length,
                                itemBuilder: (context, index) {
                                  final item = _alternatives![index];
                                  return _AlternativeCard(product: item);
                                },
                              ),
                  ),

                  const SizedBox(height: 12),

                  /// ── Compare Button ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.compare_arrows),
                      label: const Text('Compare Ingredients'),
                      onPressed: () =>
                          context.push('/compare', extra: scanResult),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Alternative Card (enhanced version)
// ─────────────────────────────────────────────────────────────────────────────
class _AlternativeCard extends StatelessWidget {
  final AlternativeProduct product;

  const _AlternativeCard({required this.product});

  Color _safetyColor(String safety) {
    final s = safety.toLowerCase();
    if (s.contains('safe') || s.contains('clean') || s.contains('natural')) {
      return AppColors.safe;
    }
    if (s.contains('better') || s.contains('plant') || s.contains('heart')) {
      return AppColors.caution;
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _safetyColor(product.safety);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(Icons.shopping_bag_outlined, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.reason,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    product.safety,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            if (product.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: product.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
