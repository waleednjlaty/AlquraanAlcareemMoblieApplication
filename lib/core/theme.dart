import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── ألوان الليل ────────────────────────────────────
class AppColors {
  static const background = Color(0xFF0B1420);
  static const surface = Color(0xFF111E30);
  static const surfaceAlt = Color(0xFF1A2A3E);
  static const gold = Color(0xFFC9A84C);
  static const goldLight = Color(0xFFE8D5A0);
  static const goldMuted = Color(0x80C9A84C);
  static const textSecondary = Color(0xFF8A9BB5);
  static const border = Color(0x25C9A84C);
  static const borderMid = Color(0x50C9A84C);
}

// ── ألوان النهار ───────────────────────────────────
class AppColorsLight {
  static const background = Color(0xFFF8F3E8);
  static const surface = Color(0xFFEEE8D8);
  static const surfaceAlt = Color(0xFFE5DDD0);
  static const gold = Color(0xFF8B6410);
  static const goldLight = Color(0xFF4A3200);
  static const goldMuted = Color(0xAA8B6410);
  static const textSecondary = Color(0xFF7A6A50);
  static const border = Color(0x408B6410);
  static const borderMid = Color(0x708B6410);
}

class AppTheme {
  // ── ثيم الليل ──────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.gold,
        secondary: AppColors.goldLight,
      ),
      textTheme: GoogleFonts.amiriTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.gold),
      ),
      dividerColor: AppColors.border,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.gold),
        trackColor: WidgetStateProperty.all(AppColors.border),
      ),
    );
  }

  // ── ثيم النهار ──────────────────────────────────
  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColorsLight.background,
      colorScheme: const ColorScheme.light(
        surface: AppColorsLight.surface,
        primary: AppColorsLight.gold,
        secondary: AppColorsLight.goldLight,
      ),
      textTheme: GoogleFonts.amiriTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsLight.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColorsLight.gold),
      ),
      dividerColor: AppColorsLight.border,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(AppColorsLight.gold),
        trackColor: WidgetStateProperty.all(AppColorsLight.border),
      ),
    );
  }
}

// ── مساعد يرجع الألوان الصحيحة حسب الثيم ──────────
class AC {
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) =>
      _isDark(context) ? AppColors.background : AppColorsLight.background;

  static Color surface(BuildContext context) =>
      _isDark(context) ? AppColors.surface : AppColorsLight.surface;

  static Color gold(BuildContext context) =>
      _isDark(context) ? AppColors.gold : AppColorsLight.gold;

  static Color goldLight(BuildContext context) =>
      _isDark(context) ? AppColors.goldLight : AppColorsLight.goldLight;

  static Color goldMuted(BuildContext context) =>
      _isDark(context) ? AppColors.goldMuted : AppColorsLight.goldMuted;

  static Color text(BuildContext context) =>
      _isDark(context) ? AppColors.textSecondary : AppColorsLight.textSecondary;

  static Color border(BuildContext context) =>
      _isDark(context) ? AppColors.border : AppColorsLight.border;

  static Color borderMid(BuildContext context) =>
      _isDark(context) ? AppColors.borderMid : AppColorsLight.borderMid;
}
