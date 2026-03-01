import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Dark Mode"),
            subtitle: const Text("Toggle app appearance"),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text("Edit Health Profile"),
            onTap: () => context.push('/health-profile'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("About IngreSafe"),
            subtitle: const Text("AI-powered ingredient safety scanner"),
          ),
        ],
      ),
    );
  }
}
