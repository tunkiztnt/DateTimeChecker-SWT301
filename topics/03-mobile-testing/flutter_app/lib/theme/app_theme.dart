import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const lightBg = Color(0xFFF1F5F9);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceSoft = Color(0xFFEFF6FF);
  static const lightText = Color(0xFF0F172A);
  static const lightMuted = Color(0xFF64748B);
  static const lightLine = Color(0xFFE2E8F0);
  static const lightPrimary = Color(0xFF1E40AF);
  static const lightAccent = Color(0xFF3B82F6);
  static const lightSuccessBg = Color(0xFFF0FDF4);
  static const lightSuccessBorder = Color(0xFFBBF7D0);
  static const lightSuccessText = Color(0xFF166534);
  static const lightErrorBg = Color(0xFFFEF2F2);
  static const lightErrorBorder = Color(0xFFFCA5A5);
  static const lightErrorText = Color(0xFF991B1B);

  static const darkBg = Color(0xFF0F172A);
  static const darkSurface = Color(0xFF1E293B);
  static const darkSurfaceSoft = Color(0xFF334155);
  static const darkText = Color(0xFFF8FAFC);
  static const darkMuted = Color(0xFF94A3B8);
  static const darkLine = Color(0xFF334155);
  static const darkPrimary = Color(0xFF3B82F6);
  static const darkAccent = Color(0xFF60A5FA);
  static const darkSuccessBg = Color(0xFF14532D);
  static const darkSuccessBorder = Color(0xFF22C55E);
  static const darkSuccessText = Color(0xFF4ADE80);
  static const darkErrorBg = Color(0xFF7F1D1D);
  static const darkErrorBorder = Color(0xFFEF4444);
  static const darkErrorText = Color(0xFFF87171);
}

class AppTheme {
  AppTheme._();

  static const double cardRadius = 16;
  static const double inputRadius = 8;
  static const double buttonRadius = 8;

  static TextTheme _buildTextTheme(TextTheme base) =>
      GoogleFonts.interTextTheme(base);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        onPrimary: Colors.white,
        secondary: AppColors.lightAccent,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightText,
        error: AppColors.lightErrorText,
        outline: AppColors.lightLine,
      ),
      textTheme: _buildTextTheme(base.textTheme),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.lightLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.lightLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.lightAccent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.lightAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightText,
          backgroundColor: const Color(0xFFF8FAFC),
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: AppColors.lightLine),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: Colors.white,
        secondary: AppColors.darkAccent,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText,
        error: AppColors.darkErrorText,
        outline: AppColors.darkLine,
      ),
      textTheme: _buildTextTheme(base.textTheme),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.darkLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.darkLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkText,
          backgroundColor: AppColors.darkSurfaceSoft,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: AppColors.darkLine),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

extension AppColorsExtension on ColorScheme {
  Color get surfaceSoft => brightness == Brightness.light
      ? AppColors.lightSurfaceSoft
      : AppColors.darkSurfaceSoft;

  Color get muted => brightness == Brightness.light
      ? AppColors.lightMuted
      : AppColors.darkMuted;

  Color get line => brightness == Brightness.light
      ? AppColors.lightLine
      : AppColors.darkLine;

  Color get bg =>
      brightness == Brightness.light ? AppColors.lightBg : AppColors.darkBg;

  Color get successBg => brightness == Brightness.light
      ? AppColors.lightSuccessBg
      : AppColors.darkSuccessBg.withValues(alpha: 0.22);

  Color get successBorder => brightness == Brightness.light
      ? AppColors.lightSuccessBorder
      : AppColors.darkSuccessBorder.withValues(alpha: 0.35);

  Color get successText => brightness == Brightness.light
      ? AppColors.lightSuccessText
      : AppColors.darkSuccessText;

  Color get errorBg => brightness == Brightness.light
      ? AppColors.lightErrorBg
      : AppColors.darkErrorBg.withValues(alpha: 0.22);

  Color get errorBorder => brightness == Brightness.light
      ? AppColors.lightErrorBorder
      : AppColors.darkErrorBorder.withValues(alpha: 0.35);

  Color get errorText => brightness == Brightness.light
      ? AppColors.lightErrorText
      : AppColors.darkErrorText;
}
