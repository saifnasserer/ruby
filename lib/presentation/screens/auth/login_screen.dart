import 'package:flutter/material.dart';
import 'package:ruby/features/weekly_view/views/weekly_view_page.dart';
import 'package:ruby/core/services/auth_service.dart';
import 'package:ruby/features/settings/controllers/settings_controller.dart';
import 'package:ruby/core/theme/ruby_theme.dart';
import 'dart:ui';

class LoginScreen extends StatefulWidget {
  final SettingsController? settingsController;

  const LoginScreen({super.key, this.settingsController});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "فشل تسجيل الدخول. يرجى المحاولة مرة أخرى.\n($e)";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاتصال: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
    final primaryColor = RubyTheme.primary(context);
    // Always use a dark background for the action body to match the high-contrast inspiration
    final bodyBgColor = isDark
        ? const Color(0xFF0F0F0F)
        : const Color(0xFF1A1A1A);
    final headerColor = Colors.white;
    final subTextColor = Colors.white.withOpacity(0.7);

    return Scaffold(
      backgroundColor: bodyBgColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 1. Wavy Header (Light)
              ClipPath(
                clipper: WavyClipper(),
                child: Container(
                  height: 380,
                  width: double.infinity,
                  color: headerColor,
                  child: Stack(
                    children: [
                      // Background Pattern for Header
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.2,
                          child: Image.asset(
                            'assets/pattern.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 60),
                              const Text(
                                'تسجيل\nالدخول',
                                style: TextStyle(
                                  fontFamily: 'NotoSansArabic',
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(
                                height: 80,
                              ), // Leave space for wave
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Body section (Dark) - Clean without pattern
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'مرحباً بك في Ruby. سجل الدخول لمزامنة مهامك على السحابة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 16,
                        color: subTextColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),

                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    // Primary Action: Google Sign In with Premium Gradient Border
                    _isLoading
                        ? CircularProgressIndicator(color: primaryColor)
                        : Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor,
                                  Colors.purple,
                                  Colors.blue,
                                ],
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(1.5), // border width
                              decoration: BoxDecoration(
                                color: bodyBgColor,
                                borderRadius: BorderRadius.circular(28.5),
                              ),
                              child: ElevatedButton(
                                onPressed: _handleGoogleSignIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28.5),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.g_mobiledata, size: 36),
                                    SizedBox(width: 8),
                                    Text(
                                      'الاستمرار باستخدام Google',
                                      style: TextStyle(
                                        fontFamily: 'NotoSansArabic',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                    const SizedBox(height: 24),

                    // Secondary Action: Skip Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: OutlinedButton(
                        onPressed: _handleSkip,
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 1.5,
                          ),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'تخطي والمتابعة كضيف',
                          style: TextStyle(
                            fontFamily: 'NotoSansArabic',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: subTextColor,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _SocialCircleButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 40),
      ),
    );
  }
}

class WavyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 80);

    var firstStart = Offset(size.width / 4, size.height);
    var firstEnd = Offset(size.width / 2.25, size.height - 50.0);
    path.quadraticBezierTo(
      firstStart.dx,
      firstStart.dy,
      firstEnd.dx,
      firstEnd.dy,
    );

    var secondStart = Offset(
      size.width - (size.width / 3.24),
      size.height - 105,
    );
    var secondEnd = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(
      secondStart.dx,
      secondStart.dy,
      secondEnd.dx,
      secondEnd.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
