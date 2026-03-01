import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ingresafe/widgets/state/empty_state_widget.dart';
import '../utils/theme_constants.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mockHistory = [
      {
        "product": "Chocolate Spread",
        "risk": "Caution",
        "color": AppColors.caution,
      },
      {"product": "Protein Bar", "risk": "Safe", "color": AppColors.safe},
      {
        "product": "Instant Noodles",
        "risk": "Risky",
        "color": AppColors.danger,
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Scan History")),

      body: mockHistory.isEmpty
          ? EmptyStateWidget(
              title: "No Scans Yet",
              subtitle:
                  "Start scanning product labels to see your safety analysis history here.",
              action: ElevatedButton(
                onPressed: () => context.go('/scan'),
                child: const Text("Scan Your First Product"),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: ListView.builder(
                itemCount: mockHistory.length,
                itemBuilder: (context, index) {
                  final item = mockHistory[index];
                  final color = item["color"] as Color;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Icon(Icons.inventory_2, color: color),
                      ),
                      title: Text(item["product"] as String),
                      subtitle: const Text("Tap to view full analysis"),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
