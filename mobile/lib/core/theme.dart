import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFF0D1117);
  static const surface = Color(0xFF161B22);
  static const card = Color(0xFF1C2333);
  static const border = Color(0xFF30363D);
  static const cyan = Color(0xFF00D9FF);
  static const cyanDim = Color(0x2600D9FF);
  static const amber = Color(0xFFF59E0B);
  static const amberDim = Color(0x26F59E0B);
  static const red = Color(0xFFEF4444);
  static const redDim = Color(0x26EF4444);
  static const green = Color(0xFF22C55E);
  static const greenDim = Color(0x2622C55E);
  static const orange = Color(0xFFF97316);
  static const orangeDim = Color(0x26F97316);
  static const textPrimary = Color(0xFFF0F6FC);
  static const textSecondary = Color(0xFF8B949E);
  static const textMuted = Color(0xFF484F58);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cyan,
        surface: AppColors.surface,
        error: AppColors.red,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    );
  }

  static Color severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical': return AppColors.red;
      case 'high': return AppColors.orange;
      case 'medium': return AppColors.amber;
      default: return AppColors.green;
    }
  }

  static Color severityDim(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical': return AppColors.redDim;
      case 'high': return AppColors.orangeDim;
      case 'medium': return AppColors.amberDim;
      default: return AppColors.greenDim;
    }
  }
}
