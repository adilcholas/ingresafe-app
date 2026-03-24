import 'package:go_router/go_router.dart';
import 'package:ingresafe/models/ingredient_model.dart';
import 'package:ingresafe/models/scan_result.dart';
import 'package:ingresafe/providers/user_provider.dart';
import 'package:ingresafe/screens/alternatives_screen.dart';
import 'package:ingresafe/screens/app_shell.dart';
import 'package:ingresafe/screens/compare_screen.dart';
import 'package:ingresafe/screens/error_screen.dart';
import 'package:ingresafe/screens/history_screen.dart';
import 'package:ingresafe/screens/ingredient_detail_screen.dart';
import 'package:ingresafe/screens/login_screen.dart';
import 'package:ingresafe/screens/onboarding_screen.dart';
import 'package:ingresafe/screens/processing_screen.dart';
import 'package:ingresafe/screens/register_screen.dart';
import 'package:ingresafe/screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/health_profile_screen.dart';
import '../screens/scan_screen.dart';
import '../screens/result_screen.dart';

class AppRouter {
  // Routes accessible WITHOUT authentication
  static const _publicRoutes = {
    '/',
    '/onboarding',
    '/login',
    '/register',
  };

  static GoRouter buildRouter(UserProvider userProvider) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: userProvider,
      redirect: (context, state) {
        final status = userProvider.status;
        final path = state.uri.path;

        // Still loading — stay on splash
        if (status == AuthStatus.unknown) {
          return path == '/' ? null : '/';
        }

        final isPublic = _publicRoutes.contains(path);
        final isAuthed = status == AuthStatus.authenticated;

        // Not logged in, trying to access a protected route → login
        if (!isAuthed && !isPublic) return '/login';

        // Already logged in, visiting login/register → go home
        if (isAuthed && (path == '/login' || path == '/register')) {
          return '/home';
        }

        return null; // no redirect
      },
      routes: [
        // ─── Public routes ─────────────────────────────────────────────────
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
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),

        // ─── Protected full-screen routes ──────────────────────────────────
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

        // ─── Shell route with bottom nav ───────────────────────────────────
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
}
