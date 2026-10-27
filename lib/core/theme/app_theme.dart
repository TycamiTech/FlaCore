import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme defines the "Ultra-Clean Soft Neumorphism" design system for FlaCore.
class AppTheme {
  AppTheme._();

  // Core Monochromatic Palette
  static const Color backgroundColor = Color(0xFFF4F7FB); // Cool Soft Blue Porcelain
  static const Color textPrimary = Color(0xFF1E232E); // Dark charcoal
  static const Color textSecondary = Color(0xFF6B7385); // Neutral soft slate gray
  static const Color textMuted = Color(0xFF8C93A0); // Very light gray

  // Neumorphic Shadow Colors (Ultra-Clean Diffused)
  static const Color shadowLight = Color(0xFFFFFFFF);
  static const Color shadowDark = Color(0x1F7A859E); // 12% alpha soft slate

  // Inset / Concave Gradient Colors
  static const Color concaveGradientStart = Color(0xFFE7ECF3);
  static const Color concaveGradientEnd = Color(0xFFF8FAFD);

  // Glassmorphic Colors
  static const Color glassBackground = Color(0xD9FFFFFF); // 85% opacity white
  static const Color glassBorder = Color(0x99FFFFFF); // 60% opacity white

  // Monochromatic Primary Accents (no aggressive blues)
  static const Color primaryAccent = Color(0xFF1E232E);
  static const Color secondaryAccent = Color(0xFF6B7385);

  // ===========================================================================
  // Neumorphic / Soft UI BoxDecoration Helpers
  // ===========================================================================

  /// Convex Neumorphic Decoration (Timbul):
  /// Uses two ultra-soft opposing diffused shadows:
  /// - Top-left: White (#FFFFFF) offset (-6, -6) blur 14
  /// - Bottom-right: Soft Slate (#1F7A859E) offset (6, 6) blur 14
  static BoxDecoration neumorphicConvex({
    double borderRadius = 18,
    BorderRadiusGeometry? customBorderRadius,
    Color color = const Color(0xFFFFFFFF),
    BoxShape shape = BoxShape.rectangle,
    Border? border,
  }) {
    return BoxDecoration(
      color: color,
      shape: shape,
      borderRadius: shape == BoxShape.circle
          ? null
          : (customBorderRadius ?? BorderRadius.circular(borderRadius)),
      border: border,
      boxShadow: const [
        BoxShadow(
          color: shadowLight,
          offset: Offset(-6, -6),
          blurRadius: 14,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: shadowDark,
          offset: Offset(6, 6),
          blurRadius: 14,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Concave / Inset Neumorphic Decoration (Cekung):
  /// Creates an illusion of a recessed surface using soft gradient direction and inset boundary shadows.
  static BoxDecoration neumorphicConcave({
    double borderRadius = 18,
    BorderRadiusGeometry? customBorderRadius,
    BoxShape shape = BoxShape.rectangle,
    List<Color> gradientColors = const [
      concaveGradientStart,
      concaveGradientEnd,
    ],
    Border? border,
  }) {
    return BoxDecoration(
      shape: shape,
      borderRadius: shape == BoxShape.circle
          ? null
          : (customBorderRadius ?? BorderRadius.circular(borderRadius)),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      ),
      border: border ??
          Border.all(
            color: const Color(0x1F7A859E),
            width: 1,
          ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1F7A859E),
          offset: Offset(2, 2),
          blurRadius: 4,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: Color(0x99FFFFFF),
          offset: Offset(-2, -2),
          blurRadius: 4,
          spreadRadius: -1,
        ),
      ],
    );
  }

  /// Glassmorphic Decoration:
  /// Semi-transparent white surface with a fine hairline border and soft ambient blur shadow.
  static BoxDecoration glassmorphic({
    double borderRadius = 28,
    BorderRadiusGeometry? customBorderRadius,
    BoxShape shape = BoxShape.rectangle,
    Color color = glassBackground,
    Color borderColor = glassBorder,
    double borderWidth = 1.0,
  }) {
    return BoxDecoration(
      color: color,
      shape: shape,
      borderRadius: shape == BoxShape.circle
          ? null
          : (customBorderRadius ?? BorderRadius.circular(borderRadius)),
      border: Border.all(
        color: borderColor,
        width: borderWidth,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F000000),
          offset: Offset(0, 8),
          blurRadius: 24,
        ),
        BoxShadow(
          color: Color(0x1A7A859E),
          offset: Offset(0, 2),
          blurRadius: 10,
        ),
      ],
    );
  }

  // ===========================================================================
  // Flutter ThemeData
  // ===========================================================================

  static ThemeData get lightTheme {
    final fontFamily = GoogleFonts.inter().fontFamily;
    final baseTheme = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primaryAccent,
        onPrimary: Colors.white,
        secondary: secondaryAccent,
        onSecondary: Colors.white,
        error: Color(0xFFE74C3C),
        onError: Colors.white,
        surface: backgroundColor,
        onSurface: textPrimary,
      ),
    );

    return baseTheme.copyWith(
      scaffoldBackgroundColor: backgroundColor,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          color: textSecondary,
          fontSize: 12,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1F7A859E),
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        color: textPrimary,
      ),
    );
  }
}

/// Lightweight Soft Blue Porcelain background widget with pre-rendered blurry ambient artwork.
/// Solves GPU 100% idle issues by using a pre-baked blurry texture with 0 shader overhead.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Pre-rendered blurry ambient artwork (0% GPU shader cost)
          Positioned.fill(
            child: IgnorePointer(
              child: Image.asset(
                'images/ambient_bg.jpg',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),

          // Main Foreground Content
          child,
        ],
      ),
    );
  }
}


