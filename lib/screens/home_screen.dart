import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/scan_provider.dart';
import '../utils/app_spacing.dart';
import '../utils/theme_constants.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scanProvider = context.watch<ScanProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/scan'),
        child: const Icon(Icons.camera_alt_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Hello 👋",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Stay Safe with IngreSafe",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () => context.push('/settings'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              /// Hero Scan Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.qr_code_scanner,
                      size: 40,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Scan a Product Label",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Instant AI analysis of ingredients & safety risks",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              /// Recent Scans Title
              const Text(
                "Recent Scans",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              /// 🔥 Dynamic Recent Scans
              Expanded(
                child: scanProvider.recentScans.isEmpty
                    ? const Center(
                        child: Text(
                          "No scans yet",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: scanProvider.recentScans.length,
                        itemBuilder: (context, index) {
                          final scan = scanProvider.recentScans[index];

                          return _RecentScanCard(
                            product: scan.productName,
                            risk: scan.riskLevel,
                            color: _getRiskColor(scan.riskLevel),
                            onTap: () {
                              context.push('/scan-detail', extra: scan);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Risk Color Mapper
  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'Safe':
        return AppColors.safe;
      case 'Caution':
        return AppColors.caution;
      case 'Risky':
        return AppColors.danger;
      default:
        return Colors.grey;
    }
  }
}

/// Updated Card with tap support
class _RecentScanCard extends StatelessWidget {
  final String product;
  final String risk;
  final Color color;
  final VoidCallback? onTap;

  const _RecentScanCard({
    required this.product,
    required this.risk,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.inventory_2, color: color),
        ),
        title: Text(product),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            risk,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}