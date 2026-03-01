import 'package:go_router/go_router.dart';
import 'package:ingresafe/models/ingredient_model.dart';
import 'package:ingresafe/screens/alternatives_screen.dart';
import 'package:ingresafe/screens/error_screen.dart';
import 'package:ingresafe/screens/history_screen.dart';
import 'package:ingresafe/screens/ingredient_detail_screen.dart';
import 'package:ingresafe/screens/onboarding_screen.dart';
import 'package:ingresafe/screens/processing_screen.dart';
import 'package:ingresafe/screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/health_profile_screen.dart';
import '../screens/scan_screen.dart';
import '../screens/result_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/health-profile',
        name: 'healthProfile',
        builder: (context, state) => const HealthProfileScreen(),
      ),
      GoRoute(
        path: '/scan',
        name: 'scan',
        builder: (context, state) => ScanScreen(),
      ),
      GoRoute(
        path: '/result',
        name: 'result',
        builder: (context, state) => const ResultScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/processing',
        builder: (context, state) => const ProcessingScreen(),
      ),
      GoRoute(
        path: '/ingredient-detail',
        builder: (context, state) {
          final ingredient = state.extra as IngredientModel;
          return IngredientDetailScreen(ingredient: ingredient);
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/alternatives',
        builder: (context, state) => const AlternativesScreen(),
      ),
      GoRoute(
        path: '/error',
        builder: (context, state) => const ScanErrorScreen(),
      ),
    ],
  );
}
