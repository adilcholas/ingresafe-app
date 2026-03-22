import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_spacing.dart';
import '../utils/theme_constants.dart';
import '../widgets/common/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentIndex = 0;

  final List<Map<String, dynamic>> onboardingData = [
    {
      "title": "Scan Product Ingredients",
      "subtitle":
          "Instantly scan food, cosmetics, and labels to understand what you consume.",
      "icon": Icons.document_scanner_rounded,
    },
    {
      "title": "AI-Powered Safety Analysis",
      "subtitle":
          "Smart ingredient detection with risk categorization: Safe, Caution, Risk.",
      "icon": Icons.health_and_safety_rounded,
    },
    {
      "title": "Personalized Health Warnings",
      "subtitle": "Get alerts based on your allergies and dietary preferences.",
      "icon": Icons.warning_amber_rounded,
    },
  ];

  void nextPage() {
    if (currentIndex < onboardingData.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/health-profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: [
            const SizedBox(height: 40),

            /// Skip Button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/health-profile'),
                child: const Text("Skip"),
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  setState(() => currentIndex = index);
                },
                itemBuilder: (context, index) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// Illustration Placeholder (Replace with Lottie later)
                      Container(
                        height: 220,
                        width: 220,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          onboardingData[index]["icon"],
                          size: 100,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 40),

                      /// Title
                      Text(
                        onboardingData[index]["title"]!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      /// Subtitle
                      Text(
                        onboardingData[index]["subtitle"]!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            /// Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: currentIndex == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: currentIndex == index
                        ? AppColors.primary
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// Next / Get Started Button
            PrimaryButton(
              text: currentIndex == 2 ? "Get Started" : "Next",
              onPressed: nextPage,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
