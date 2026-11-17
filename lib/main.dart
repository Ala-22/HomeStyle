import 'package:flutter/material.dart';

import 'services/app_settings.dart';
import 'views/home_screen.dart';
import 'views/login_screen.dart';
import 'views/signup_screen.dart';
import 'views/welcome_screen.dart';

const Color _brown = Color(0xFF5D4037);
const Color _cream = Color(0xFFF7EFE5);
const Color _darkBrown = Color(0xFF1D140E);

void main() {
  runApp(const HomeStyleApp());
}

class HomeStyleApp extends StatefulWidget {
  const HomeStyleApp({super.key});

  @override
  State<HomeStyleApp> createState() => _HomeStyleAppState();
}

class _HomeStyleAppState extends State<HomeStyleApp> {
  @override
  void initState() {
    super.initState();
    AppSettings.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          title: 'HomeStyle',

          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: AppSettings.instance.themeMode,

          initialRoute: '/welcome',

          routes: {
            '/welcome': (context) => const WelcomeScreen(),
            '/home': (context) => const HomeScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
          },
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _brown,
      primary: _brown,
    );

    return _baseTheme(scheme).copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: _cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: _cream,
        foregroundColor: _brown,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _brown,
      brightness: Brightness.dark,
      primary: const Color(0xFFB89372),
    );

    return _baseTheme(scheme).copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: _darkBrown,
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBrown,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  ThemeData _baseTheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF2A2018) : Colors.white;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: TextStyle(color: scheme.onSurface),
        selectedColor: scheme.primary,
        backgroundColor: isDark
            ? const Color(0xFF2A2018)
            : Colors.brown.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? const Color(0xFF2A2018)
            : const Color(0xFFE8DCC9).withValues(alpha: 0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}