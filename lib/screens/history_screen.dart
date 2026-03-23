import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    final scans = context.watch<ScanProvider>().recentScans;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          if (scans.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear History',
              onPressed: () => _confirmClear(context),
            ),
        ],
      ),
      body: scans.isEmpty
          ? EmptyStateWidget(
              title: 'No Scans Yet',
              subtitle:
                  'Start scanning product labels to see your safety analysis history here.',
              action: ElevatedButton(
                onPressed: () => context.go('/scan'),
                child: const Text('Scan Your First Product'),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: ListView.builder(
                itemCount: scans.length,
                itemBuilder: (context, index) {
                  final scan = scans[index];
                  final color = _riskColor(scan.riskLevel);

                  return _HistoryCard(
                    scan: scan,
                    color: color,
                    timeLabel: _timeAgo(scan.scannedAt),
                    onTap: () => context.push('/result', extra: scan),
                  );
                },
              ),
            ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text('All scan records will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<ScanProvider>().clearScans();
    }
  }
}

class _HistoryCard extends StatelessWidget {
  final ScanResult scan;
  final Color color;
  final String timeLabel;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.scan,
    required this.color,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
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
          '${scan.ingredients.length} ingredients · $timeLabel',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            scan.riskLevel,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
