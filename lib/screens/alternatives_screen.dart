import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ingresafe/models/scan_result.dart';
import 'package:ingresafe/providers/scan_provider.dart';
import 'package:provider/provider.dart';

import '../utils/theme_constants.dart';
import '../widgets/common/alternative_product_card.dart';

class AlternativesScreen extends StatelessWidget {
  /// The scan passed via route extra (preferred). Falls back to latest scan.
  final ScanResult? scan;

  const AlternativesScreen({super.key, this.scan});

  @override
  Widget build(BuildContext context) {
    final scanResult =
        scan ?? context.read<ScanProvider>().recentScans.firstOrNull;

    final alternatives = scanResult != null
        ? _generateAlternatives(scanResult)
        : <_Alt>[];

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
                      children: const [
                        Icon(
                          Icons.auto_awesome,
                          color: AppColors.primary,
                          size: 30,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'AI-suggested alternatives based on your scan results.',
                            style: TextStyle(fontSize: 14),
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
                    child: alternatives.isEmpty
                        ? const Center(
                            child: Text(
                              'No specific alternatives found.\nThis product appears to have safe ingredients.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
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

                  /// ── Compare Button ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          context.push('/compare', extra: scanResult),
                      child: const Text('Compare Ingredients'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Generates alternatives based on detected risky/caution ingredients
  List<_Alt> _generateAlternatives(ScanResult result) {
    final results = <_Alt>[];

    // Use ingredient names from the scan (not raw text)
    final ingredientNames = result.ingredients
        .map((i) => i.name.toLowerCase())
        .toSet();

    if (ingredientNames.any(
      (n) =>
          n.contains('sugar') || n.contains('fructose') || n.contains('syrup'),
    )) {
      results.add(
        _Alt(
          name: 'Low Sugar Organic Spread',
          safety: 'Better Choice',
          reason: 'Significantly reduced sugar content',
          color: AppColors.caution,
        ),
      );
    }

    if (ingredientNames.any(
      (n) => n.contains('milk') || n.contains('lactose') || n.contains('dairy'),
    )) {
      results.add(
        _Alt(
          name: 'Vegan Dairy-Free Spread',
          safety: 'Safer',
          reason: 'No dairy ingredients — ideal for lactose intolerance',
          color: AppColors.safe,
        ),
      );
    }

    if (ingredientNames.any(
      (n) => n.contains('preservative') || n.contains('artificial'),
    )) {
      results.add(
        _Alt(
          name: 'Organic Clean-Label Spread',
          safety: 'Highly Safe',
          reason: 'No artificial additives or preservatives',
          color: AppColors.safe,
        ),
      );
    }

    if (ingredientNames.any(
      (n) => n.contains('gluten') || n.contains('wheat'),
    )) {
      results.add(
        _Alt(
          name: 'Gluten-Free Certified Alternative',
          safety: 'Safe for Celiac',
          reason: 'Certified gluten-free — safe for celiac disease',
          color: AppColors.safe,
        ),
      );
    }

    if (ingredientNames.any(
      (n) => n.contains('trans fat') || n.contains('saturated fat'),
    )) {
      results.add(
        _Alt(
          name: 'Heart-Healthy Low-Fat Option',
          safety: 'Heart Safe',
          reason: 'No trans fats — reduced saturated fat',
          color: AppColors.safe,
        ),
      );
    }

    // Fallback if no specific triggers found
    if (results.isEmpty) {
      results.add(
        _Alt(
          name: 'Natural Ingredient Product',
          safety: 'Safe',
          reason: 'Minimal processed ingredients — clean label',
          color: AppColors.safe,
        ),
      );
    }

    return results;
  }
}

class _Alt {
  final String name;
  final String safety;
  final String reason;
  final Color color;

  _Alt({
    required this.name,
    required this.safety,
    required this.reason,
    required this.color,
  });
}
