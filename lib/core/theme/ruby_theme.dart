import 'package:flutter/material.dart';
import '../../responsive.dart';

class RubyTheme {
  // Ruby-inspired color palette
  static const Color rubyRed = Color(0xFFE91E63); // Deep Ruby Red
  static const Color rubyPink = Color(0xFFF8BBD9); // Soft Ruby Pink
  static const Color rubyDark = Color(0xFFAD1457); // Dark Ruby
  static const Color rubyLight = Color(0xFFFCE4EC); // Light Ruby

  // Modern neutrals
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color softGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFF9E9E9E);
  static const Color darkGray = Color(0xFF424242);
  static const Color charcoal = Color(0xFF212121);

  // Accent colors
  static const Color gold = Color(0xFFFFD700); // Ruby's companion
  static const Color emerald = Color(0xFF00C853); // Success/Completion
  static const Color sapphire = Color(0xFF2196F3); // Info/Secondary

  // Priority colors
  static const Color priorityHigh = Color(0xFFFF5252); // Urgent red
  static const Color priorityMedium = Color(0xFFFFA726); // Amber
  static const Color priorityLow = Color(0xFF42A5F5); // Calm blue

  // Dark mode colors
  static const Color darkBackground = Color(0xFF121212); // Deep charcoal
  static const Color darkSurface = Color(0xFF1E1E1E); // Dark gray surface
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C); // Lighter surface

  // Dark mode text
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // Pure white
  static const Color darkTextSecondary = Color(0xFFB0B0B0); // Medium gray
  static const Color darkTextTertiary = Color(0xFF808080); // Darker gray

  // Dark mode accents (softer versions)
  static const Color darkRubyRed = Color(0xFFFF6B9D); // Softer ruby
  static const Color darkEmerald = Color(0xFF4CAF50); // Softer emerald
  static const Color darkSapphire = Color(0xFF42A5F5); // Softer sapphire
  static const Color darkGold = Color(0xFFFFD54F); // Softer gold

  // Theme-aware color getters
  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : pureWhite;
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : softGray;
  }

  static Color surfaceVariant(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurfaceVariant
        : pureWhite;
  }

  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : charcoal;
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : darkGray;
  }

  static Color textTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextTertiary
        : mediumGray;
  }

  static Color primary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkRubyRed
        : rubyRed;
  }

  static Color accent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSapphire
        : sapphire;
  }

  static Color success(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkEmerald
        : emerald;
  }

  // Gradients
  static const LinearGradient rubyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [rubyRed, rubyDark],
  );

  static const LinearGradient darkRubyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkRubyRed, Color(0xFFD81B60)],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [pureWhite, softGray],
  );

  static const LinearGradient darkSoftGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkSurface, darkBackground],
  );

  static const LinearGradient priorityHighGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [priorityHigh, Color(0xFFD32F2F)],
  );

  static const LinearGradient priorityMediumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [priorityMedium, Color(0xFFF57C00)],
  );

  static const LinearGradient priorityLowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [priorityLow, Color(0xFF1976D2)],
  );

  // Text styles - now theme-aware
  static TextStyle heading1(BuildContext context) => TextStyle(
    fontSize: Responsive.text(context, size: TextSize.heading) * 1.2,
    fontWeight: FontWeight.w700,
    color: textPrimary(context),
    fontFamily: 'NotoSansArabic',
    height: 1.2,
  );

  static TextStyle heading2(BuildContext context) => TextStyle(
    fontSize: Responsive.text(context, size: TextSize.heading),
    fontWeight: FontWeight.w600,
    color: textPrimary(context),
    fontFamily: 'NotoSansArabic',
    height: 1.3,
  );

  static TextStyle bodyLarge(BuildContext context) => TextStyle(
    fontSize: Responsive.text(context, size: TextSize.medium) * 0.9,
    fontWeight: FontWeight.w400,
    color: textSecondary(context),
    fontFamily: 'NotoSansArabic',
    height: 1.5,
  );

  static TextStyle bodyMedium(BuildContext context) => TextStyle(
    fontSize: Responsive.text(context, size: TextSize.small),
    fontWeight: FontWeight.w400,
    color: textTertiary(context),
    fontFamily: 'NotoSansArabic',
    height: 1.4,
  );

  static TextStyle caption(BuildContext context) => TextStyle(
    fontSize: Responsive.text(context, size: TextSize.small) * 0.85,
    fontWeight: FontWeight.w400,
    color: textTertiary(context),
    fontFamily: 'NotoSansArabic',
    height: 1.3,
  );

  // Shadows - theme-aware with safety checks
  static List<BoxShadow> softShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
        blurRadius: 12.0 < 0 ? 0 : 12.0,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> mediumShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
        blurRadius: 20.0 < 0 ? 0 : 20.0,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static List<BoxShadow> strongShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.5 : 0.16),
        blurRadius: 32.0 < 0 ? 0 : 32.0,
        offset: const Offset(0, 16),
      ),
    ];
  }

  // Border radius - now responsive
  static double radiusSmall(BuildContext context) =>
      Responsive.space(context, size: Space.small);
  static double radiusMedium(BuildContext context) =>
      Responsive.space(context, size: Space.medium);
  static double radiusLarge(BuildContext context) =>
      Responsive.space(context, size: Space.large);
  static double radiusXLarge(BuildContext context) =>
      Responsive.space(context, size: Space.xlarge);

  // Spacing - now responsive
  static double spacingXS(BuildContext context) =>
      Responsive.space(context, size: Space.tiny);
  static double spacingS(BuildContext context) =>
      Responsive.space(context, size: Space.small);
  static double spacingM(BuildContext context) =>
      Responsive.space(context, size: Space.medium);
  static double spacingL(BuildContext context) =>
      Responsive.space(context, size: Space.large);
  static double spacingXL(BuildContext context) =>
      Responsive.space(context, size: Space.xlarge);
  static double spacingXXL(BuildContext context) =>
      Responsive.space(context, size: Space.xlarge) * 1.5;
}
