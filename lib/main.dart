import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ingresafe/data/services/ingredient_data_service.dart';
import 'package:ingresafe/firebase_options.dart';
import 'package:ingresafe/providers/health_profile_provider.dart';
import 'package:ingresafe/providers/scan_provider.dart';
import 'package:ingresafe/providers/theme_provider.dart';
import 'package:ingresafe/providers/user_provider.dart';
import 'package:ingresafe/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Seed ingredient + alternatives dataset to Firestore (idempotent)
  IngredientDataService.seedFirestore();
  runApp(const IngreSafeApp());
}

class IngreSafeApp extends StatelessWidget {
  const IngreSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => HealthProfileProvider()),
        ChangeNotifierProvider(create: (_) => ScanProvider()),
      ],
      child: Consumer2<ThemeProvider, UserProvider>(
        builder: (context, themeProvider, userProvider, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'IngreSafe',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: AppRouter.buildRouter(userProvider),
          );
        },
      ),
    );
  }
}
