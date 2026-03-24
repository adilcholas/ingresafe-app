import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/health_profile_provider.dart';
import '../providers/scan_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../utils/theme_constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final healthProfile = context.watch<HealthProfileProvider>().profile;
    final userProvider = context.watch<UserProvider>();

    final allergiesCount = healthProfile.allergies.length;
    final dietsCount = healthProfile.dietaryPreferences.length;
    final conditionsCount = healthProfile.healthConditions.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          /// ── Account Section ──────────────────────────────────────────────
          _SectionHeader(title: 'Account'),
          _AccountTile(userProvider: userProvider),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.danger),
            ),
            onTap: () => _confirmSignOut(context),
          ),

          const Divider(),

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
                    'IngreSafe processes images locally on your device using Google ML Kit. '
                    'Scan history is securely stored in Firebase Firestore, '
                    'linked to your account.\n\n'
                    'Your health profile is encrypted and persisted per user account.',
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

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('You will need to sign in again to access your data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<UserProvider>().signOut();
      // Router redirect handles navigation to /login
    }
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

// ─────────────────────────────────────────────────────────────────────────────
// Account Tile — shows avatar, name, email
// ─────────────────────────────────────────────────────────────────────────────
class _AccountTile extends StatelessWidget {
  final UserProvider userProvider;
  const _AccountTile({required this.userProvider});

  @override
  Widget build(BuildContext context) {
    final initial = userProvider.displayName.isNotEmpty
        ? userProvider.displayName[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProvider.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userProvider.email,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.safe.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                color: AppColors.safe,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
