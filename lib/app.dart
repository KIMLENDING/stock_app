import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

/// 주식 앱 — 다크 테마 기반 MaterialApp
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '주식 앱',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4FC3F7),
          secondary: Color(0xFF81D4FA),
          surface: Color(0xFF161B22),
          error: Color(0xFFEF5350),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D1117),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0D1117),
          selectedItemColor: Color(0xFF4FC3F7),
          unselectedItemColor: Color(0xFF6E7681),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Color(0xFFC9D1D9)),
          bodySmall: TextStyle(color: Color(0xFF8B949E)),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
