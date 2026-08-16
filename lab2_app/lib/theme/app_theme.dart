import 'package:flutter/material.dart';

class AppTheme {
  // Primary accent color
  static const Color primaryColor = Color(0xFF3F51B5); // Indigo
  static const Color secondaryColor = Color(0xFF5C6BC0);
  static const Color accentColor = Color(0xFF7986CB);
  static const Color backgroundColor = Color(0xFFF8F9FD);
  static const Color surfaceColor = Colors.white;
  static const Color onSurfaceColor = Color(0xFF1A1D2E);
  static const Color subtleText = Color(0xFF757B8A);
  static const Color dividerColor = Color(0xFFE8EAEE);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: dividerColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: onSurfaceColor),
        titleTextStyle: TextStyle(
          color: onSurfaceColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // Text Styles
  static const TextStyle displayStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: onSurfaceColor,
    height: 1.2,
  );

  static const TextStyle headingStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: onSurfaceColor,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: onSurfaceColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: onSurfaceColor,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: subtleText,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: subtleText,
  );

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  // Box Shadow
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
}
