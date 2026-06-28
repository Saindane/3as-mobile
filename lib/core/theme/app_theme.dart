import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const primary     = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1E3A8A);
  static const primaryLight= Color(0xFFDBEAFE);
  static const success     = Color(0xFF16A34A);
  static const successLight= Color(0xFFDCFCE7);
  static const warning     = Color(0xFFD97706);
  static const warningLight= Color(0xFFFEF3C7);
  static const error       = Color(0xFFDC2626);
  static const errorLight  = Color(0xFFFEE2E2);
  static const surface     = Color(0xFFFFFFFF);
  static const background  = Color(0xFFF8FAFC);
  static const border      = Color(0xFFE2E8F0);
  static const text        = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted   = Color(0xFF94A3B8);
  static const slate100    = Color(0xFFF1F5F9);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.surface,
      background: AppColors.background,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.slate100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
    ),
    cardTheme: CardTheme(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

// ── Text style helpers ────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();
  static const heading1 = TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.text, fontFamily: 'Inter');
  static const heading2 = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text, fontFamily: 'Inter');
  static const heading3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text, fontFamily: 'Inter');
  static const body     = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary, fontFamily: 'Inter');
  static const bodyBold = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text, fontFamily: 'Inter');
  static const caption  = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted, fontFamily: 'Inter');
  static const label    = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontFamily: 'Inter', letterSpacing: 0.4);
}
