import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ingresafe/firebase_options.dart';
import 'package:ingresafe/providers/health_profile_provider.dart';
import 'package:ingresafe/providers/scan_provider.dart';
import 'package:ingresafe/providers/theme_provider.dart';
import 'package:ingresafe/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        ChangeNotifierProvider(create: (_) => HealthProfileProvider()),
        ChangeNotifierProvider(create: (_) => ScanProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'IngreSafe',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
