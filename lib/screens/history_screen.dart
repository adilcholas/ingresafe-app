import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ingresafe/data/services/scan_history_service.dart';
import 'package:ingresafe/models/scan_result.dart';
import 'package:ingresafe/providers/scan_provider.dart';
import 'package:ingresafe/widgets/state/empty_state_widget.dart';
import 'package:provider/provider.dart';
import '../utils/theme_constants.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

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
        return Icons.check_circle_outline;
      case 'Risky':
        return Icons.dangerous_outlined;
      default:
        return Icons.warning_amber_outlined;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScanProvider>();
    final scans = provider.recentScans;
    final isLoading = provider.isLoadingHistory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          if (scans.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear All History',
              onPressed: () => _confirmClearAll(context),
            ),
        ],
      ),
      body: isLoading
          ? _buildShimmer()
          : scans.isEmpty
              ? EmptyStateWidget(
                  title: 'No Scans Yet',
                  subtitle:
                      'Start scanning product labels to see your safety analysis history here.',
                  action: ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan Your First Product'),
                    onPressed: () => context.go('/scan'),
                  ),
                )
              : Column(
                  children: [
                    /// ── Summary Banner ─────────────────────────────────────
                    _SummaryBanner(scans: scans),

                    /// ── List ───────────────────────────────────────────────
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        itemCount: scans.length,
                        itemBuilder: (context, index) {
                          final scan = scans[index];
                          return _HistoryCard(
                            scan: scan,
                            color: _riskColor(scan.riskLevel),
                            icon: _riskIcon(scan.riskLevel),
                            timeLabel: _timeAgo(scan.scannedAt),
                            onTap: () => context.push('/result', extra: scan),
                            onDelete: () => _deleteScan(context, scan),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: 6,
      itemBuilder: (ctx, i) => _ShimmerCard(),
    );
  }

  Future<void> _deleteScan(BuildContext context, ScanResult scan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Scan?'),
        content: Text(
          'Remove "${scan.productName}" from history?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = context.read<ScanProvider>();
      // Remove from Firestore if persisted
      if (scan.firestoreId != null) {
        await ScanHistoryService.deleteScan(scan.firestoreId!);
      }
      // Reload history to sync state
      await provider.reloadHistory();
    }
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text('All scan records will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<ScanProvider>().clearScans();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary Banner
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryBanner extends StatelessWidget {
  final List<ScanResult> scans;

  const _SummaryBanner({required this.scans});

  @override
  Widget build(BuildContext context) {
    final safe = scans.where((s) => s.riskLevel == 'Safe').length;
    final caution = scans.where((s) => s.riskLevel == 'Caution').length;
    final risky = scans.where((s) => s.riskLevel == 'Risky').length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(label: 'Total', value: '${scans.length}', color: AppColors.primary),
          _StatChip(label: 'Safe', value: '$safe', color: AppColors.safe),
          _StatChip(label: 'Caution', value: '$caution', color: AppColors.caution),
          _StatChip(label: 'Risky', value: '$risky', color: AppColors.danger),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History Card
// ─────────────────────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final ScanResult scan;
  final Color color;
  final IconData icon;
  final String timeLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.scan,
    required this.color,
    required this.icon,
    required this.timeLabel,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(scan.firestoreId ?? scan.scannedAt.toIso8601String()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // we handle removal ourselves via reloadHistory
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                /// Risk Icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),

                const SizedBox(width: 14),

                /// Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scan.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          const Icon(
                            Icons.science_outlined,
                            size: 13,
                            color: Colors.grey,
                          ),
                          Text(
                            '${scan.ingredients.length} ingredients',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.access_time,
                            size: 13,
                            color: Colors.grey,
                          ),
                          Text(
                            timeLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                /// Risk Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        scan.riskLevel,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer placeholder card
// ─────────────────────────────────────────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.04, end: 0.14).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, child) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: _anim.value * 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: _anim.value),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: _anim.value * 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
