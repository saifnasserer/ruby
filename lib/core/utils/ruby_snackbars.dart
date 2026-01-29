import 'package:flutter/material.dart';

class RubySnackBar {
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message,
      Colors.greenAccent,
      Icons.check_circle_outline_rounded,
    );
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, Colors.redAccent, Icons.error_outline_rounded);
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message,
      const Color(0xFFFFD700), // Gold/Amber
      Icons.info_outline_rounded,
    );
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A), // Softer dark background
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'NotoSansArabic',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        duration: const Duration(milliseconds: 2500),
      ),
    );
  }
}
