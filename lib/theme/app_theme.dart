import 'package:flutter/material.dart';

enum AppStyle { paper, studio, night }

class AppPalette {
  const AppPalette({
    required this.name,
    required this.description,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.accentSoft,
    required this.secondary,
    required this.secondarySoft,
    required this.line,
    required this.isDark,
    required this.radius,
  });

  final String name;
  final String description;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color accentSoft;
  final Color secondary;
  final Color secondarySoft;
  final Color line;
  final bool isDark;
  final double radius;
}

class PaletteTheme extends ThemeExtension<PaletteTheme> {
  const PaletteTheme(this.palette);

  final AppPalette palette;

  @override
  PaletteTheme copyWith({AppPalette? palette}) {
    return PaletteTheme(palette ?? this.palette);
  }

  @override
  PaletteTheme lerp(covariant ThemeExtension<PaletteTheme>? other, double t) {
    return this;
  }
}

AppPalette paletteFor(AppStyle style) {
  switch (style) {
    case AppStyle.paper:
      return const AppPalette(
        name: '书房纸张',
        description: '温和、沉静，适合长时间阅读',
        background: Color(0xFFF4F1EA),
        surface: Color(0xFFFFFDF8),
        surfaceAlt: Color(0xFFE7EEE8),
        ink: Color(0xFF19272B),
        muted: Color(0xFF6D7977),
        accent: Color(0xFF0E6B5A),
        accentSoft: Color(0xFFD9EAE2),
        secondary: Color(0xFFE17A55),
        secondarySoft: Color(0xFFF7DFD4),
        line: Color(0xFFD9DDD5),
        isDark: false,
        radius: 22,
      );
    case AppStyle.studio:
      return const AppPalette(
        name: '清透蓝图',
        description: '清晰、利落，适合快速完成任务',
        background: Color(0xFFEEF3F8),
        surface: Color(0xFFFFFFFF),
        surfaceAlt: Color(0xFFE3EBF7),
        ink: Color(0xFF152238),
        muted: Color(0xFF6B7789),
        accent: Color(0xFF2457D6),
        accentSoft: Color(0xFFDCE6FB),
        secondary: Color(0xFFE39A42),
        secondarySoft: Color(0xFFF8E7CD),
        line: Color(0xFFD9E1ED),
        isDark: false,
        radius: 14,
      );
    case AppStyle.night:
      return const AppPalette(
        name: '夜读专注',
        description: '低干扰、强对比，适合晚间复习',
        background: Color(0xFF141A1C),
        surface: Color(0xFF20292A),
        surfaceAlt: Color(0xFF2C3B37),
        ink: Color(0xFFF3F3E9),
        muted: Color(0xFFA8B5AE),
        accent: Color(0xFFA8D76B),
        accentSoft: Color(0xFF30422F),
        secondary: Color(0xFF5BC5C2),
        secondarySoft: Color(0xFF263F40),
        line: Color(0xFF354440),
        isDark: true,
        radius: 12,
      );
  }
}

ThemeData themeFor(AppStyle style) {
  final palette = paletteFor(style);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: palette.accent,
        brightness: palette.isDark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: palette.accent,
        onPrimary: palette.isDark ? const Color(0xFF162116) : Colors.white,
        secondary: palette.secondary,
        onSecondary: palette.isDark ? const Color(0xFF102222) : Colors.white,
        surface: palette.surface,
        onSurface: palette.ink,
        outline: palette.line,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.background,
    canvasColor: palette.background,
    dividerColor: palette.line,
    fontFamily: 'Arial',
    extensions: [PaletteTheme(palette)],
    textTheme: TextTheme(
      displaySmall: TextStyle(
        color: palette.ink,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.05,
      ),
      headlineSmall: TextStyle(
        color: palette.ink,
        fontSize: 25,
        fontWeight: FontWeight.w800,
        height: 1.1,
      ),
      titleLarge: TextStyle(
        color: palette.ink,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        color: palette.ink,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(color: palette.ink, fontSize: 16, height: 1.45),
      bodyMedium: TextStyle(color: palette.muted, fontSize: 14, height: 1.4),
      labelLarge: TextStyle(
        color: palette.ink,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.accentSoft,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          color: palette.muted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(color: palette.muted, size: 22),
      ),
      height: 72,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      hintStyle: TextStyle(color: palette.muted),
      prefixIconColor: palette.muted,
      suffixIconColor: palette.muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(palette.radius),
        borderSide: BorderSide(color: palette.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(palette.radius),
        borderSide: BorderSide(color: palette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(palette.radius),
        borderSide: BorderSide(color: palette.accent, width: 1.5),
      ),
    ),
  );
}
