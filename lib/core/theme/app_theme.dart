import 'package:flutter/material.dart';

/// Premium light civic theme for VIGÍA — Apple-inspired light mode.
/// Pristine light neutrals, authentic frosted glass tokens, refined indigo accent.
/// Zero institutional green, strict WCAG 2.1 AA contrast compliance.
class AppTheme {
  // ─── Primary Accent (Refined Indigo) ───
  static const Color accent = Color(0xFF4F46E5);       // Indigo 600
  static const Color accentLight = Color(0xFF6366F1);  // Indigo 500
  static const Color accentSoft = Color(0xFFEEF2FF);   // Indigo 50
  static const Color accentSurface = Color(0xFFE0E7FF);// Indigo 100
  static const Color accentDark = Color(0xFF3730A3);   // Indigo 800

  // ─── Road Alert (Warm Amber) ───
  static const Color accentAlert = Color(0xFFF59E0B);
  static const Color accentAlertLight = Color(0xFFFEF3C7);
  static const Color accentAlertDark = Color(0xFFB45309);

  // ─── Neutral Foundation (Apple Zinc/Slate) ───
  static const Color dark950 = Color(0xFF09090B);  // Zinc 950
  static const Color dark900 = Color(0xFF18181B);  // Zinc 900
  static const Color dark800 = Color(0xFF27272A);  // Zinc 800
  static const Color dark700 = Color(0xFF3F3F46);  // Zinc 700
  static const Color dark600 = Color(0xFF52525B);  // Zinc 600
  static const Color dark500 = Color(0xFF71717A);  // Zinc 500
  static const Color dark400 = Color(0xFFA1A1AA);  // Zinc 400
  static const Color dark300 = Color(0xFFD4D4D8);  // Zinc 300
  static const Color dark200 = Color(0xFFE4E4E7);  // Zinc 200
  static const Color dark100 = Color(0xFFF4F4F5);  // Zinc 100
  static const Color dark50 = Color(0xFFFAFAFA);   // Zinc 50

  // ─── Semantic Light Aliases ───
  static const Color background = Color(0xFFF8FAFC);      // Slate 50 clean light canvas
  static const Color surface = Color(0xFFFFFFFF);         // Pure white
  static const Color surfaceElevated = Color(0xFFFFFFFF); // White card
  static const Color textPrimary = Color(0xFF0F172A);     // Slate 900 (WCAG AA > 14:1)
  static const Color textSecondary = Color(0xFF475569);   // Slate 600
  static const Color textMuted = Color(0xFF64748B);       // Slate 500
  static const Color borderLight = Color(0xFFE2E8F0);     // Slate 200
  static const Color borderSubtle = Color(0xFFF1F5F9);    // Slate 100
  static const Color borderDark = dark300;

  // ─── Glass Tokens (glass.md — Light Mode Frosted Glass) ───
  static const Color glassBackground = Color(0xD1FFFFFF); // White 82%
  static const Color glassBorder = Color(0xF2FFFFFF);     // White 95% specular highlight
  static const Color glassBorderSubtle = Color(0x1F0F172A);// 12% subtle outline
  static const Color glassInputFill = Color(0xF2FFFFFF);  // White 95%

  // ─── Status Semantic Colors ───
  static const Color statusSuccess = Color(0xFF16A34A);       // Emerald 600
  static const Color statusSuccessBg = Color(0xFFECFDF5);     // Emerald 50
  static const Color statusSuccessBorder = Color(0xFFA7F3D0); // Emerald 200
  static const Color statusError = Color(0xFFDC2626);         // Red 600
  static const Color statusErrorBg = Color(0xFFFEF2F2);       // Red 50
  static const Color statusErrorBorder = Color(0xFFFECACA);   // Red 200

  // ─── Backward-compatible aliases for dashboard and existing components ───
  static const Color primaryCivic = accent;
  static const Color primaryDark = accentDark;
  static const Color primaryLight = accentSoft;
  static const Color primarySurface = accentSurface;
  static const Color primaryMedium = accentLight;
  static const Color backgroundLight = background;
  static const Color surfaceLight = surface;
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  // ─── Apple Shadows ───
  static final List<BoxShadow> cardShadow = [
    const BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
    const BoxShadow(
      color: Color(0x050F172A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> buttonShadow = [
    const BoxShadow(
      color: Color(0x38000000),
      blurRadius: 18,
      offset: Offset(0, 6),
      spreadRadius: -2,
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: accent,
        secondary: accentLight,
        surface: surface,
        error: statusError,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderLight, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderLight, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: statusError, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: statusError, width: 1.8),
        ),
        labelStyle: const TextStyle(
          color: textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: const TextStyle(
          color: accent,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(color: slate400, fontSize: 14),
        prefixIconColor: slate500,
        suffixIconColor: slate500,
        errorStyle: const TextStyle(color: statusError, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: slate200,
          disabledForegroundColor: slate400,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: borderLight, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: borderLight, width: 1.0),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark900,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
