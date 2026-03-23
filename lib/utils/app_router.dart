import 'package:go_router/go_router.dart';
import 'package:ingresafe/models/ingredient_model.dart';
import 'package:ingresafe/models/scan_result.dart';
import 'package:ingresafe/screens/alternatives_screen.dart';
import 'package:ingresafe/screens/app_shell.dart';
import 'package:ingresafe/screens/compare_screen.dart';
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
      // ─── Full-screen routes (no bottom nav) ────────────────────────────────
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
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
        path: '/processing',
        name: 'processing',
        builder: (context, state) => const ProcessingScreen(),
      ),
      GoRoute(
        path: '/result',
        name: 'result',
        builder: (context, state) {
          final scan = state.extra as ScanResult?;
          return ResultScreen(scan: scan);
        },
      ),
      GoRoute(
        path: '/ingredient-detail',
        name: 'ingredientDetail',
        builder: (context, state) {
          final ingredient = state.extra as IngredientModel;
          return IngredientDetailScreen(ingredient: ingredient);
        },
      ),
      GoRoute(
        path: '/alternatives',
        name: 'alternatives',
        builder: (context, state) {
          final scan = state.extra as ScanResult?;
          return AlternativesScreen(scan: scan);
        },
      ),
      GoRoute(
        path: '/compare',
        name: 'compare',
        builder: (context, state) {
          final scan = state.extra as ScanResult?;
          return CompareScreen(scan: scan);
        },
      ),
      GoRoute(
        path: '/error',
        name: 'scanError',
        builder: (context, state) => const ScanErrorScreen(),
      ),

      // ─── Shell route with bottom nav ───────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/history',
            name: 'history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}
