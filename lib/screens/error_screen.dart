import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/state/error_state_widget.dart';

class ScanErrorScreen extends StatelessWidget {
  const ScanErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ErrorStateWidget(
        title: "No Ingredients Detected",
        message:
            "We couldn’t detect a clear ingredient list. Try scanning in better lighting or align the label properly.",
        onRetry: () => context.go('/scan'),
      ),
    );
  }
}