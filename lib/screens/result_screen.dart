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

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Analysis Result')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ── Risk Score Card ─────────────────────────────────────────────
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

            const SizedBox(height: 16),

            /// ── Personalized Warnings ────────────────────────────────────────
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
                    Row(
                      children: const [
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

            /// ── Ingredients Title ────────────────────────────────────────────
            const Text(
              'Ingredients Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            /// ── Ingredient Cards ─────────────────────────────────────────────
            Expanded(
              child: scanResult.ingredients.isEmpty
                  ? const Center(
                      child: Text(
                        'No recognisable ingredients found in the scan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: scanResult.ingredients.length,
                      itemBuilder: (context, index) {
                        return _IngredientCard(
                          ingredient: scanResult.ingredients[index],
                        );
                      },
                    ),
            ),

            const SizedBox(height: 12),

            /// ── Alternatives Button ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.push('/alternatives', extra: scanResult);
                },
                child: const Text('View Safer Alternatives'),
              ),
            ),
          ],
        ),
      ),
    ));
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
