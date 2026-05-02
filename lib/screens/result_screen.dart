import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ingresafe/models/ingredient_model.dart';
import 'package:ingresafe/models/scan_result.dart';
import 'package:ingresafe/providers/health_profile_provider.dart';
import 'package:ingresafe/providers/scan_provider.dart';
import 'package:provider/provider.dart';
import '../utils/theme_constants.dart';

class ResultScreen extends StatelessWidget {
  /// Passed via GoRouter extra (preferred) or falls back to ScanProvider.currentScan
  final ScanResult? scan;

  const ResultScreen({super.key, this.scan});

  @override
  Widget build(BuildContext context) {
    // Prefer route-passed scan; fallback to provider's currentScan
    final scanResult = scan ?? context.read<ScanProvider>().currentScan;
    final healthProfile = context.watch<HealthProfileProvider>().profile;

    if (scanResult == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analysis Result')),
        body: const Center(
          child: Text(
            'No scan data found.\nPlease scan a product first.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final riskColor = _riskColor(scanResult.riskLevel);
    final riskIcon = _riskIcon(scanResult.riskLevel);
    final riskLabel = _riskLabel(scanResult.riskLevel);

    // Personalized warnings: ingredients that match user's allergies/conditions
    final personalizedWarnings = scanResult.ingredients.where((ing) {
      final matchesAllergen =
          ing.allergenKey != null &&
          healthProfile.allergies.contains(ing.allergenKey);
      final matchesCondition =
          ing.conditionKey != null &&
          healthProfile.healthConditions.contains(ing.conditionKey);
      return matchesAllergen || matchesCondition;
    }).toList();

    // Separate known (has real risk data) vs unknown (not in database) ingredients
    final knownIngredients = scanResult.ingredients
        .where((ing) => ing.description != 'No additional risk information available.')
        .toList();

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Analysis Result')),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  /// ── Risk Score Card ─────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: riskColor,
                          child: Icon(riskIcon, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          riskLabel,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: riskColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          scanResult.productName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ── Personalized Warnings ──────────────────────────────────
                  if (personalizedWarnings.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.danger,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Personalized Warnings',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...personalizedWarnings.map(
                            (ing) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '• ${ing.name}: ${ing.description}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  /// ── Ingredients Found (Full List) ──────────────────────────
                  if (scanResult.ingredients.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.list_alt_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Ingredients Found (${scanResult.ingredients.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: scanResult.ingredients.map((ing) {
                          final color = _riskColor(ing.riskLevel);
                          final isKnown = ing.description !=
                              'No additional risk information available.';
                          return GestureDetector(
                            onTap: () => context.push(
                              '/ingredient-detail',
                              extra: ing,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isKnown
                                    ? color.withValues(alpha: 0.12)
                                    : Theme.of(context)
                                        .dividerColor
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isKnown
                                      ? color.withValues(alpha: 0.4)
                                      : Theme.of(context)
                                          .dividerColor
                                          .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isKnown)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: color,
                                      ),
                                    ),
                                  Flexible(
                                    child: Text(
                                      ing.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isKnown
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: isKnown
                                            ? color
                                            : Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  /// ── Ingredients Analysis Title ─────────────────────────────
                  if (knownIngredients.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.analytics_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Ingredients Analysis (${knownIngredients.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    /// ── Ingredient Cards ─────────────────────────────────────
                    ...knownIngredients.map(
                      (ing) => _IngredientCard(ingredient: ing),
                    ),
                  ],

                  if (knownIngredients.isEmpty && scanResult.ingredients.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.info_outline, size: 40, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'No detailed risk data available for these ingredients.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'These are likely common food ingredients with no known concerns.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                  if (scanResult.ingredients.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'No recognisable ingredients found in the scan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            /// ── Alternatives Button ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/alternatives', extra: scanResult);
                  },
                  child: const Text('View Safer Alternatives'),
                ),
              ),
            ),
          ],
        ),
      ),
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

  IconData _riskIcon(String risk) {
    switch (risk) {
      case 'Safe':
        return Icons.check_circle;
      case 'Risky':
        return Icons.dangerous;
      default:
        return Icons.warning;
    }
  }

  String _riskLabel(String risk) {
    switch (risk) {
      case 'Safe':
        return 'GENERALLY SAFE';
      case 'Risky':
        return 'HIGH RISK — AVOID';
      default:
        return 'USE WITH CAUTION';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ingredient Card
// ─────────────────────────────────────────────────────────────────────────────
class _IngredientCard extends StatelessWidget {
  final IngredientModel ingredient;

  const _IngredientCard({required this.ingredient});

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

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(ingredient.riskLevel);

    return GestureDetector(
      onTap: () => context.push('/ingredient-detail', extra: ingredient),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(Icons.science, color: color),
          ),
          title: Text(ingredient.name),
          subtitle: Text(
            ingredient.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
        ),
      ),
    );
  }
}
