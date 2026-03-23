import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/health_profile_provider.dart';
import '../providers/scan_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final healthProfile = context.watch<HealthProfileProvider>().profile;

    final allergiesCount = healthProfile.allergies.length;
    final dietsCount = healthProfile.dietaryPreferences.length;
    final conditionsCount = healthProfile.healthConditions.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          /// ── Appearance Section ───────────────────────────────────────────
          _SectionHeader(title: 'Appearance'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle app appearance'),
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.toggleTheme(value),
          ),

          const Divider(),

          /// ── Health Profile Section ───────────────────────────────────────
          _SectionHeader(title: 'Health Profile'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Edit Health Profile'),
            subtitle: Text(
              '$allergiesCount allergies · $dietsCount diets · $conditionsCount conditions',
              style: const TextStyle(fontSize: 13),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/health-profile'),
          ),

          const Divider(),

          /// ── Data Section ─────────────────────────────────────────────────
          _SectionHeader(title: 'Data'),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Scan History'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/history'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text(
              'Clear All Scan Data',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _confirmClearData(context),
          ),

          const Divider(),

          /// ── About Section ────────────────────────────────────────────────
          _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About IngreSafe'),
            subtitle: const Text('AI-powered ingredient safety scanner'),
            trailing: const Text(
              'v0.1.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Privacy Policy'),
                  content: const Text(
                    'IngreSafe processes all images locally on your device using Google ML Kit. '
                    'No images or personal data are uploaded to any server.\n\n'
                    'Your health profile data is stored only on this device.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          /// ── Footer ───────────────────────────────────────────────────────
          Center(
            child: Text(
              'Made with ❤️ for safer food choices',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _confirmClearData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will delete all your scan history. This cannot be undone.',
        ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Scan history cleared.')));
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
