import 'package:flutter/material.dart';
import '../models/ingredient_model.dart';
import '../utils/theme_constants.dart';

class IngredientDetailScreen extends StatelessWidget {
  final IngredientModel ingredient;

  const IngredientDetailScreen({
    super.key,
    required this.ingredient,
  });

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'safe':
        return AppColors.safe;
      case 'caution':
        return AppColors.caution;
      case 'risky':
        return AppColors.danger;
      default:
        return AppColors.caution;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor(ingredient.riskLevel);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ingredient Analysis"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            /// Ingredient Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: riskColor,
                    child: const Icon(Icons.science,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ingredient.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ingredient.riskLevel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// Quick Summary
            const Text(
              "Quick Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              ingredient.description,
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),

            const SizedBox(height: 24),

            /// Detailed Explanation
            const Text(
              "Why This Ingredient Matters",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              ingredient.detailedExplanation,
              style: const TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 24),

            /// Personalized Impact Card (KEY AI UX)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline,
                      color: AppColors.danger),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ingredient.userImpact,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// Regulatory Note (Trust Factor)
            const Text(
              "Regulatory Insight",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              ingredient.regulatoryNote,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}