import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/scan_result.dart';
import '../providers/health_profile_provider.dart';
import '../providers/scan_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_spacing.dart';
import '../utils/theme_constants.dart';

Future<void> _runDemoScan(BuildContext context) async {
  final provider = context.read<ScanProvider>();
  // Start demo scan (non-blocking: navigate immediately, processing screen watches)
  provider.loadDemoScan();
  if (context.mounted) {
    context.push('/processing');
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scanProvider = context.watch<ScanProvider>();
    final healthProfile = context.watch<HealthProfileProvider>().profile;
    final userProvider = context.watch<UserProvider>();
    final userName = userProvider.displayName;

    // Greeting based on health profile completeness
    final hasProfile =
        healthProfile.allergies.isNotEmpty ||
        healthProfile.dietaryPreferences.isNotEmpty ||
        healthProfile.healthConditions.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ── Header ────────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hello 👋',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hi, $userName',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () => context.push('/settings'),
                      ),
                    ),
                  ],
                ),
  
                const SizedBox(height: AppSpacing.sectionGap),
  
                /// ── Health Profile Alert (if not set) ─────────────────────────
                if (!hasProfile)
                  GestureDetector(
                    onTap: () => context.push('/health-profile'),
                    child: Container(
                      margin: const EdgeInsets.only(
                        bottom: AppSpacing.sectionGap,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.caution.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.caution.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.caution,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Set up your health profile for personalized warnings',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppColors.caution,
                          ),
                        ],
                      ),
                    ),
                  ),
  
                /// ── Hero Scan Card ─────────────────────────────────────────────
                GestureDetector(
                  onTap: () => context.push('/scan'),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
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
                                'Scan a Product Label',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Instant AI analysis of ingredients & safety risks',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
  
                const SizedBox(height: 12),
  
                /// ── Demo Scan Card ─────────────────────────────────────────────
                GestureDetector(
                  onTap: () => _runDemoScan(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.safe.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.safe.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          size: 28,
                          color: AppColors.safe,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Try Demo Scan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.safe,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Preview all features with a sample product',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.safe,
                        ),
                      ],
                    ),
                  ),
                ),
  
                const SizedBox(height: AppSpacing.sectionGap),
  
                /// ── Recent Scans Title ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Scans',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (scanProvider.recentScans.isNotEmpty)
                      TextButton(
                        onPressed: () => context.push('/history'),
                        child: const Text('See All'),
                      ),
                  ],
                ),
  
                const SizedBox(height: 12),
  
                /// ── Recent Scans List ──────────────────────────────────────────
                scanProvider.recentScans.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.document_scanner_outlined,
                                size: 60,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No scans yet.\nTap the camera button to start.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: scanProvider.recentScans.length,
                        itemBuilder: (context, index) {
                          final scan = scanProvider.recentScans[index];
                          return _RecentScanCard(
                            scan: scan,
                            color: _getRiskColor(scan.riskLevel),
                            onTap: () => context.push('/result', extra: scan),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'Safe':
        return AppColors.safe;
      case 'Risky':
        return AppColors.danger;
      default:
        return AppColors.caution;
    }
  }
}

class _RecentScanCard extends StatelessWidget {
  final ScanResult scan;
  final Color color;
  final VoidCallback? onTap;

  const _RecentScanCard({required this.scan, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.inventory_2, color: color),
        ),
        title: Text(
          scan.productName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${scan.ingredients.length} ingredients detected',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            scan.riskLevel,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
