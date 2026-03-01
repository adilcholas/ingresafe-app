import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../utils/theme_constants.dart';

class AiLoader extends StatelessWidget {
  final String lottiePath;
  final double size;

  const AiLoader({
    super.key,
    required this.lottiePath,
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: FutureBuilder(
        future: _checkIfAssetExists(context, lottiePath),
        builder: (context, snapshot) {
          /// If asset exists → Show Lottie
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.data == true) {
            return Lottie.asset(
              lottiePath,
              repeat: true,
              fit: BoxFit.contain,
            );
          }

          /// Fallback → Circular Loader (SAFE UX)
          return const CircularProgressIndicatorWrapper();
        },
      ),
    );
  }

  Future<bool> _checkIfAssetExists(
      BuildContext context, String path) async {
    try {
      await DefaultAssetBundle.of(context).load(path);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class CircularProgressIndicatorWrapper extends StatelessWidget {
  const CircularProgressIndicatorWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 4,
      ),
    );
  }
}