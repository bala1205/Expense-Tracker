import 'package:expense_track/data/data.dart';
import 'package:expense_track/screens/auth/auth_screen.dart';
import 'package:expense_track/screens/home/views/home_screen.dart';
import 'package:flutter/material.dart';

class MyAppView extends StatelessWidget {
  const MyAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppData.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Expense Tracker",
          themeMode: mode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: ValueListenableBuilder(
            valueListenable: AppData.user,
            builder: (context, user, _) {
              return user == null ? const AuthScreen() : const HomeScreen();
            },
          ),
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        surface: isDark ? const Color(0xFF141414) : Colors.grey.shade100,
        onSurface: isDark ? Colors.white : Colors.black,
        primary: const Color(0xFF00B2E7),
        onPrimary: Colors.white,
        secondary: const Color(0xFFE064F7),
        onSecondary: Colors.white,
        tertiary: const Color(0xFFFF8D6C),
        onTertiary: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF141414) : Colors.grey.shade100,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1D1D1D) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
    );
  }
}