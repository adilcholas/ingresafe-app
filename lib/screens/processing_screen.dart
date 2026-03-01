import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ingresafe/widgets/common/ai_loader.dart';
import 'package:lottie/lottie.dart';
import '../utils/theme_constants.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  @override
  void initState() {
    super.initState();
    _simulateAnalysis();
  }

  Future<void> _simulateAnalysis() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      context.go('/result');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// Animated Loader
              const AiLoader(lottiePath: 'assets/lottie/ai_loading.json'),
              const SizedBox(height: 30),

              const Text(
                "Analyzing Ingredients...",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              const Text(
                "AI + Safety Engine is evaluating the product label",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 40),

              /// Analysis Steps UX
              const _AnalysisStep(text: "Extracting Ingredients (OCR)"),
              const _AnalysisStep(text: "Matching Safety Database"),
              const _AnalysisStep(text: "Generating Risk Score"),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisStep extends StatelessWidget {
  final String text;
  const _AnalysisStep({required this.text});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.check_circle_outline),
      title: Text(text),
    );
  }
}
