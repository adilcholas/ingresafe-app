import 'package:flutter/material.dart';
import '../utils/theme_constants.dart';
import '../widgets/common/alternative_product_card.dart';

class AlternativesScreen extends StatelessWidget {
  const AlternativesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    /// Mock AI Recommended Alternatives (Future: API/Firebase)
    final alternatives = [
      {
        "name": "Organic Cocoa Spread",
        "safety": "Safer",
        "reason": "No artificial additives & lactose-free",
        "color": AppColors.safe,
      },
      {
        "name": "Vegan Chocolate Spread",
        "safety": "Highly Safe",
        "reason": "Dairy-free and allergy-friendly ingredients",
        "color": AppColors.safe,
      },
      {
        "name": "Low Sugar Nutri Spread",
        "safety": "Better Choice",
        "reason": "Reduced sugar and cleaner ingredient list",
        "color": AppColors.caution,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Safer Alternatives"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header Insight Card (AI Explanation UX)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: const [
                  Icon(Icons.auto_awesome, color: AppColors.primary, size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "AI has suggested safer alternatives based on your health profile and ingredient risk analysis.",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// Section Title
            const Text(
              "Recommended Safer Products",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            /// Alternatives List
            Expanded(
              child: ListView.builder(
                itemCount: alternatives.length,
                itemBuilder: (context, index) {
                  final item = alternatives[index];
                  return AlternativeProductCard(
                    productName: item["name"] as String,
                    safetyLevel: item["safety"] as String,
                    reason: item["reason"] as String,
                    riskColor: item["color"] as Color,
                  );
                },
              ),
            ),

            /// Compare Button (Future AI Feature)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text("Compare Ingredients"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}