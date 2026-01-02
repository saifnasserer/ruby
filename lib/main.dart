import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ruby/features/weekly_view/views/weekly_view_page.dart';
import 'package:ruby/core/services/local_notification_service.dart';
import 'package:ruby/features/settings/controllers/settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await LocalNotificationService.instance.initialize();

  // Initialize settings
  final prefs = await SharedPreferences.getInstance();
  final settingsController = SettingsController(prefs);

  runApp(Ruby(settingsController: settingsController));
}

class Ruby extends StatelessWidget {
  final SettingsController settingsController;

  const Ruby({super.key, required this.settingsController});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WeeklyViewPage(settingsController: settingsController),
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
