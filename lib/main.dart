import 'package:flutter/material.dart';
import 'package:ruby/presentation/views/home.dart';

void main() {
  runApp(const Ruby());
}

class Ruby extends StatelessWidget {
  const Ruby({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Todo(),
      theme: ThemeData(
        fontFamily: 'NotoSansArabic',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'NotoSansArabic'),
          displayMedium: TextStyle(fontFamily: 'NotoSansArabic'),
          displaySmall: TextStyle(fontFamily: 'NotoSansArabic'),
          headlineLarge: TextStyle(fontFamily: 'NotoSansArabic'),
          headlineMedium: TextStyle(fontFamily: 'NotoSansArabic'),
          headlineSmall: TextStyle(fontFamily: 'NotoSansArabic'),
          titleLarge: TextStyle(fontFamily: 'NotoSansArabic'),
          titleMedium: TextStyle(fontFamily: 'NotoSansArabic'),
          titleSmall: TextStyle(fontFamily: 'NotoSansArabic'),
          bodyLarge: TextStyle(fontFamily: 'NotoSansArabic'),
          bodyMedium: TextStyle(fontFamily: 'NotoSansArabic'),
          bodySmall: TextStyle(fontFamily: 'NotoSansArabic'),
          labelLarge: TextStyle(fontFamily: 'NotoSansArabic'),
          labelMedium: TextStyle(fontFamily: 'NotoSansArabic'),
          labelSmall: TextStyle(fontFamily: 'NotoSansArabic'),
        ),
      ),
    );
  }
}
