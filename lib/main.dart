import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ruby/features/weekly_view/views/weekly_view_page.dart';
import 'package:ruby/core/services/local_notification_service.dart';
import 'package:ruby/features/settings/controllers/settings_controller.dart';
import 'package:ruby/core/services/auth_service.dart';
import 'package:ruby/presentation/screens/auth/login_screen.dart';

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
    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: settingsController.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: 'NotoSansArabic',
            scaffoldBackgroundColor: const Color(0xFFFFFFFF),
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
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'NotoSansArabic',
            scaffoldBackgroundColor: const Color(0xFF121212),
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
          home: StreamBuilder(
            stream: AuthService.instance.authStateChange,
            builder: (context, snapshot) {
              // Show app if authenticated OR guest mode is enabled
              if (AuthService.instance.isAuthenticated ||
                  settingsController.isGuestMode) {
                return WeeklyViewPage(settingsController: settingsController);
              }
              // Otherwise show login
              return LoginScreen(settingsController: settingsController);
            },
          ),
        );
      },
    );
  }
}
