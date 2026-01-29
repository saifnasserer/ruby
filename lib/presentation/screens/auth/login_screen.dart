import 'package:flutter/material.dart';
import 'package:ruby/features/weekly_view/views/weekly_view_page.dart';
import 'package:ruby/core/services/auth_service.dart';
import 'package:ruby/core/services/sync_service.dart';
import 'package:ruby/features/settings/controllers/settings_controller.dart';
import 'package:ruby/core/theme/ruby_theme.dart';
import 'package:ruby/core/utils/ruby_snackbars.dart';

class LoginScreen extends StatefulWidget {
  final SettingsController? settingsController;

  const LoginScreen({super.key, this.settingsController});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.instance.signInWithGoogle();
      if (mounted && widget.settingsController != null) {
        widget.settingsController!.setFirstLaunch(false);
      }

      // Trigger sync immediately after successful login
      if (mounted && AuthService.instance.isAuthenticated) {
        await SyncService.instance.sync();
      }

      if (mounted) {
        RubySnackBar.showSuccess(context, "اهلاً بيك في بكيزة! ✨");

        if (Navigator.canPop(context)) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) Navigator.pop(context);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        RubySnackBar.showError(context, "حصلت مشكلة في الدخول. جرب تاني كدا.");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleSkip() {
    if (widget.settingsController != null) {
      widget.settingsController!.setGuestMode(true);
      widget.settingsController!.setFirstLaunch(false);
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              WeeklyViewPage(settingsController: widget.settingsController!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F0F) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              // Spacer to push content to center
              const Spacer(flex: 2),

              // Logo with gradient background
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: RubyTheme.priorityLowGradient,
                  boxShadow: [
                    BoxShadow(
                      color: RubyTheme.priorityLow.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    'assets/Untitled design.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // App name
              Text(
                'بكيزة',
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),

              const Spacer(flex: 3),

              // Primary button - Google Sign In with gradient
              _isLoading
                  ? SizedBox.shrink()
                  : Text(
                      'عشان تاسكاتك تتزامن على كل الأجهزة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 13,
                        color: subtextColor.withOpacity(0.7),
                        height: 1.4,
                      ),
                    ),
              SizedBox(height: 8),
              _isLoading
                  ? CircularProgressIndicator(
                      color: isDark ? Colors.white : RubyTheme.priorityLow,
                    )
                  : Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: RubyTheme.priorityLowGradient,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: RubyTheme.priorityLow.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _handleGoogleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

              // const SizedBox(height: 8),

              // Subtitle text

              // const SizedBox(height: 8),

              // Secondary button - Skip
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: _handleSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: subtextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    'كمل كضيف',
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: subtextColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
