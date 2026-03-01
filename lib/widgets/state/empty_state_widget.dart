import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../utils/theme_constants.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? lottieAsset;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.lottieAsset,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (lottieAsset != null)
              SizedBox(
                height: 180,
                child: Lottie.asset(
                  lottieAsset!,
                  repeat: true,
                ),
              )
            else
              Icon(
                Icons.inbox_outlined,
                size: 80,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),

            const SizedBox(height: 24),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),

            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ]
          ],
        ),
      ),
    );
  }
}