import 'package:flutter/material.dart';
import 'package:juridibot/theme/app_theme.dart';
import 'package:juridibot/pages/home_page.dart';

void main() {
  runApp(const JuridiBotApp());
}

class JuridiBotApp extends StatelessWidget {
  const JuridiBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JuridiBot Maroc',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
