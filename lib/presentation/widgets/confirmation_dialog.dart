import 'package:flutter/material.dart';
import '../../core/theme/ruby_theme.dart';

/// Shows a confirmation dialog with customizable title, message, and actions
Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required VoidCallback onConfirm,
  IconData confirmIcon = Icons.delete_outline,
  Color? confirmColor,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: RubyTheme.surface(context),
        contentPadding: EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: RubyTheme.heading2(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              message,
              style: RubyTheme.bodyMedium(
                context,
              ).copyWith(color: RubyTheme.mediumGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context, false),
            style: IconButton.styleFrom(
              shape: CircleBorder(),
              backgroundColor: RubyTheme.softGray,
            ),
            icon: Icon(Icons.close, color: RubyTheme.mediumGray, size: 20),
          ),
          IconButton(
            onPressed: () {
              Navigator.pop(context, true);
              onConfirm();
            },
            style: IconButton.styleFrom(
              shape: CircleBorder(),
              backgroundColor: confirmColor ?? RubyTheme.priorityHigh,
            ),
            icon: Icon(confirmIcon, color: RubyTheme.pureWhite, size: 20),
          ),
        ],
        actionsPadding: EdgeInsets.fromLTRB(20, 0, 20, 12),
      ),
    ),
  );
}
