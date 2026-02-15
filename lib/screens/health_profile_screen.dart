import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class HealthProfileScreen extends StatelessWidget {
  const HealthProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Health Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              const Text('Add your allergies & preferences'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  provider.completeProfile();
                  context.go('/scan');
                },
                child: const Text('Continue to Scan'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
