import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FarmColors {
  // Primary: Meaningful deep green (Growth, Stability) - Material 3 seed
  static const Color primary = Color(0xFF0F5132); // Deep forest green
  static const Color onPrimary = Colors.white;

  // Secondary/Accent: Vibrant, tech-forward neon green (AI, Energy)
  static const Color accent = Color(0xFF00E676);
  static const Color onAccent = Colors.black;

  // Surface & Background (Clean, airy, organic)
  static const Color background =
      Color(0xFFF9FBF9); // Very subtle cool green tint
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFE8F5E9); // Light mint for cards
  static const Color surfaceContainer =
      Color(0xFFF1F8F2); // M3 surface container

  // Text Colors
  static const Color textPrimary = Color(0xFF1B262C); // Nearly black, softer
  static const Color textSecondary = Color(0xFF546E7A); // Blue-grey

  // Functional
  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFAB00);
}

class FarmTextStyles {
  // Headings - Using Roboto for Vietnamese unicode support
  static TextStyle get heading1 => GoogleFonts.roboto(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: FarmColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get heading2 => GoogleFonts.roboto(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: FarmColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get heading3 => GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: FarmColors.textPrimary,
      );

  // Body - Using Roboto for Vietnamese unicode support
  static TextStyle get bodyLarge => GoogleFonts.roboto(
        fontSize: 16,
        color: FarmColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.roboto(
        fontSize: 14,
        color: FarmColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get button => GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get labelSmall => GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: FarmColors.textSecondary,
      );
}

class FarmStyles {
  // Shadows for depth - Material 3 style
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: FarmColors.primary.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: FarmColors.primary.withValues(alpha: 0.12),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  // Material 3 standard radii
  static BorderRadius get cardRadius => BorderRadius.circular(16);
  static BorderRadius get buttonRadius => BorderRadius.circular(12);
  static BorderRadius get chipRadius => BorderRadius.circular(8);

  // Gradients
  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [FarmColors.primary, Color(0xFF146c43)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
