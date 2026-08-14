import 'package:flutter/material.dart';

/// 웹 앱 tailwind 오렌지/그레이 팔레트에 맞춤 (구 팔레트 — 점진적으로 Cozy 팔레트로 대체 중)
class ChowColors {
  ChowColors._();

  static const orange500 = Color(0xFFF97316);
  static const orange400 = Color(0xFFFB923C);
  static const orange600 = Color(0xFFEA580C);
  static const orange50 = Color(0xFFFFF7ED);
  static const orange100 = Color(0xFFFFEDD5);
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray800 = Color(0xFF1F2937);
  static const gray900 = Color(0xFF111827);
  static const yellow400 = Color(0xFFFACC15);
  static const yellow500 = Color(0xFFEAB308);
  static const yellow600 = Color(0xFFCA8A04);
  static const kakaoYellow = Color(0xFFFEE500);
  static const kakaoYellowHover = Color(0xFFFDD835);
  static const blue500 = Color(0xFF3B82F6);
  static const purple500 = Color(0xFFA855F7);
  static const red500 = Color(0xFFEF4444);
  static const green500 = Color(0xFF22C55E);
  static const pink500 = Color(0xFFEC4899);
}

/// Cozy Minimalism 팔레트 — 신규 Figma 디자인(샌디/스톤 톤) 기준.
/// 새 페이지 리스킨은 전부 이 토큰을 사용한다.
class ChowCozy {
  ChowCozy._();

  static const stone50 = Color(0xFFFDFCF9);
  static const stone100 = Color(0xFFF5F0E8);
  static const stone200 = Color(0xFFEDE5D8);
  static const stone300 = Color(0xFFE2D8C8);
  static const stone400 = Color(0xFFD0C3B2); // 샌디 — 프라이머리 액센트
  static const stone500 = Color(0xFFC0AFA0);
  static const stone600 = Color(0xFFB09888);
  static const stone700 = Color(0xFF927F7B); // 딥 액센트 전용
  static const stone800 = Color(0xFF6E5C58);
  static const stone900 = Color(0xFF3B3230);
  static const stone950 = Color(0xFF241C1A);

  static const background = Color(0xFFFAF8F4);
  static const foreground = stone900;
  static const card = Colors.white;
  static const cardForeground = stone900;
  static const primary = stone400;
  static const primaryForeground = stone900;
  static const secondary = stone200;
  static const secondaryForeground = stone900;
  static const muted = Color(0xFFE8E0D4);
  static const mutedForeground = Color(0xFF9A8C88);
  static const accent = stone400;
  static const accentForeground = stone900;
  static const destructive = Color(0xFFA85050);
  static const destructiveForeground = Colors.white;
  static const border = Color(0x38B4A294); // rgba(180,162,148,0.22)
  static const inputBackground = stone200;
  static const switchBackground = Color(0xFFC8BFB3);
  static const radius = 10.0; // 0.625rem
}

ThemeData buildChowTheme() {
  const seed = ChowCozy.primary;
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: ChowCozy.primary,
      onPrimary: ChowCozy.primaryForeground,
      secondary: ChowCozy.secondary,
      onSecondary: ChowCozy.secondaryForeground,
      surface: ChowCozy.card,
      onSurface: ChowCozy.foreground,
      error: ChowCozy.destructive,
      onError: ChowCozy.destructiveForeground,
    ),
    scaffoldBackgroundColor: ChowCozy.background,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: ChowCozy.background,
      foregroundColor: ChowCozy.foreground,
      titleTextStyle: TextStyle(
        color: ChowCozy.foreground,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: ChowCozy.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChowCozy.radius + 6),
        side: const BorderSide(color: ChowCozy.border),
      ),
    ),
    dividerTheme: const DividerThemeData(color: ChowCozy.border, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ChowCozy.inputBackground,
      hintStyle: const TextStyle(color: ChowCozy.mutedForeground),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ChowCozy.radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ChowCozy.radius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ChowCozy.radius),
        borderSide: const BorderSide(color: ChowCozy.stone600, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ChowCozy.radius),
        ),
        backgroundColor: ChowCozy.primary,
        foregroundColor: ChowCozy.primaryForeground,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ChowCozy.radius),
        ),
        side: const BorderSide(color: ChowCozy.border),
        foregroundColor: ChowCozy.foreground,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: ChowCozy.stone700),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: ChowCozy.foreground),
      bodyMedium: TextStyle(color: ChowCozy.foreground),
    ).apply(bodyColor: ChowCozy.foreground, displayColor: ChowCozy.foreground),
  );
}
