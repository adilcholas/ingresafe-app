import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ingresafe/models/ingredient_model.dart';
import '../utils/theme_constants.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Analysis Result")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// Risk Score Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.caution.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: const [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.caution,
                    child: Icon(Icons.warning, color: Colors.white, size: 40),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "USE WITH CAUTION",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.caution,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Contains ingredients that may not suit your profile",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// Personalized Warning Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: const [
                  Icon(Icons.error_outline, color: AppColors.danger),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Warning: Contains Lactose (Not suitable for lactose intolerance)",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// Ingredient List Title
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Ingredients Analysis",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            /// Ingredient Cards
            Expanded(
              child: ListView(
                children: const [
                  _IngredientCard(
                    name: "Sugar",
                    risk: "Moderate",
                    color: AppColors.caution,
                    description: "High sugar content may affect health",
                  ),
                  _IngredientCard(
                    name: "Milk Solids",
                    risk: "High",
                    color: AppColors.danger,
                    description: "May trigger lactose intolerance",
                  ),
                  _IngredientCard(
                    name: "Cocoa Butter",
                    risk: "Safe",
                    color: AppColors.safe,
                    description: "Generally safe ingredient",
                  ),
                ],
              ),
            ),
            /// Alternatives Button
            ElevatedButton(
              onPressed: () {
                context.push('/alternatives');
              },
              child: const Text("View Safer Alternatives"),
            ),
            
          ],
        ),
      ),
    );
  }
}

class _IngredientCard extends StatelessWidget {
  final String name;
  final String risk;
  final Color color;
  final String description;

  const _IngredientCard({
    required this.name,
    required this.risk,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final ingredient = IngredientModel(
      name: name,
      riskLevel: risk,
      description: description,
      detailedExplanation:
          "$name is commonly used in processed foods. Excess consumption or sensitivity may affect certain users depending on their health profile.",
      userImpact:
          "Based on your health profile, this ingredient may trigger sensitivity or dietary conflicts.",
      regulatoryNote:
          "Approved for use in regulated quantities, but moderation is advised as per food safety guidelines.",
    );

    return GestureDetector(
      onTap: () {
        context.push('/ingredient-detail', extra: ingredient);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(Icons.science, color: color),
          ),
          title: Text(name),
          subtitle: Text(description),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
        ),
      ),
    );
  }
}
