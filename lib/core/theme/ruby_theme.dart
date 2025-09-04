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

  // Gradients
  static const LinearGradient rubyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [rubyRed, rubyDark],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [pureWhite, softGray],
  );

  // Text styles - now responsive
  static TextStyle heading1(BuildContext context) => TextStyle(
    fontSize: Responsive.text(context, size: TextSize.heading) * 1.2,
    fontWeight: FontWeight.w700,
    color: charcoal,
    fontFamily: 'NotoSansArabic',
    height: 1.2,
  );

  static TextStyle heading2(BuildContext context) => TextStyle(
    fontSize: Responsive.text(context, size: TextSize.heading),
    fontWeight: FontWeight.w600,
    color: charcoal,
    fontFamily: 'NotoSansArabic',
    height: 1.3,
  );

  static TextStyle bodyLarge(BuildContext context) => TextStyle(
    fontSize: Responsive.text(context, size: TextSize.medium) * 0.9,
    fontWeight: FontWeight.w400,
    color: darkGray,
    fontFamily: 'NotoSansArabic',
    height: 1.5,
  );

  static TextStyle bodyMedium(BuildContext context) => TextStyle(
    fontSize: Responsive.text(context, size: TextSize.small),
    fontWeight: FontWeight.w400,
    color: mediumGray,
    fontFamily: 'NotoSansArabic',
    height: 1.4,
  );

  static TextStyle caption(BuildContext context) => TextStyle(
    fontSize: Responsive.text(context, size: TextSize.small) * 0.85,
    fontWeight: FontWeight.w400,
    color: mediumGray,
    fontFamily: 'NotoSansArabic',
    height: 1.3,
  );

  // Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get strongShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.16),
      blurRadius: 32,
      offset: const Offset(0, 16),
    ),
  ];

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
