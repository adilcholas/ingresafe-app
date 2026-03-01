import 'package:flutter/material.dart';

class AlternativeProductCard extends StatelessWidget {
  final String productName;
  final String safetyLevel;
  final String reason;
  final Color riskColor;

  const AlternativeProductCard({
    super.key,
    required this.productName,
    required this.safetyLevel,
    required this.reason,
    required this.riskColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            /// Product Icon Placeholder (Future: Product Image)
            CircleAvatar(
              radius: 26,
              backgroundColor: riskColor.withValues(alpha: 0.15),
              child: Icon(Icons.shopping_bag, color: riskColor),
            ),

            const SizedBox(width: 16),

            /// Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reason,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            /// Safety Badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                safetyLevel,
                style: TextStyle(
                  color: riskColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}