import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "멍냥밥상" 로고 리브랜딩 팔레트. 메인 색 = 로고의 '밥상' 그린, 서브 색 = '멍냥'의
/// 딥그린. 구 오렌지/그레이 스케일 자리는 그대로 두고 값만 새 팔레트로 교체 —
/// 참조하던 코드는 수정 없이 갱신됨.
class ChowColors {
  ChowColors._();

  static const orange500 = Color(0xFF6BAE45); // 메인(밥상 그린)
  static const orange400 = Color(0xFF8FC46B); // 메인 라이트
  static const orange600 = Color(0xFF2E6B3E); // 서브(멍냥 딥그린)
  static const orange50 = Color(0xFFEAF5E2);
  static const orange100 = Color(0xFFDCEAD2);
  static const gray50 = Color(0xFFFBF6EA); // 배경(로고 크림)
  static const gray100 = Color(0xFFF1EDE1);
  static const gray200 = Color(0xFFE4DFCF);
  static const gray300 = Color(0xFFD3CDBB);
  static const gray400 = Color(0xFFA8A192);
  static const gray500 = Color(0xFF7A7468); // 보조 텍스트
  static const gray600 = Color(0xFF5C5850);
  static const gray700 = Color(0xFF403D38);
  static const gray800 = Color(0xFF2A2823);
  static const gray900 = Color(0xFF1B1B1B); // 본문(거의 검정)
  static const yellow400 = Color(0xFFEFC670);
  static const yellow500 = Color(0xFFE9B949);
  static const yellow600 = Color(0xFFCA9B2E);
  static const kakaoYellow = Color(0xFFFEE500);
  static const kakaoYellowHover = Color(0xFFFDD835);
  static const blue500 = Color(0xFF4A90E2);
  static const purple500 = Color(0xFFA855F7);
  static const red500 = Color(0xFFD9534F);
  static const green500 = Color(0xFF6BAE45);
  static const pink500 = Color(0xFFEC4899);
}

/// 앱 전체 디자인 토큰. 새 페이지는 전부 이 토큰을 사용한다.
class ChowCozy {
  ChowCozy._();

  static const stone50 = Color(0xFFFBF6EA); // 배경(로고 크림)
  static const stone100 = Color(0xFFF1EDE1);
  static const stone200 = Color(0xFFE4DFCF);
  static const stone300 = Color(0xFFD3CDBB);
  static const stone400 = Color(0xFFA8A192);
  static const stone500 = Color(0xFF7A7468); // 보조 텍스트
  static const stone600 = Color(0xFF5C5850);
  static const stone700 = Color(0xFF403D38);
  static const stone800 = Color(0xFF2A2823);
  static const stone900 = Color(0xFF1B1B1B); // 본문(거의 검정)
  static const stone950 = Color(0xFF121210);

  static const background = Color(0xFFFBF6EA);
  static const foreground = stone900;
  static const card = Color(0xFFFFFFFF);
  static const cardForeground = stone900;

  // 메인 색 — 로고 '밥상' 그린
  static const primary = Color(0xFF6BAE45);
  static const primaryLight = Color(0xFFEAF5E2);
  static const primaryForeground = Color(0xFFFFFFFF);

  // 서브 색 — 로고 '멍냥' 딥그린
  static const secondary = Color(0xFF2E6B3E);
  static const secondaryForeground = Color(0xFFFFFFFF);

  static const muted = primaryLight;
  static const mutedForeground = stone500;
  static const accent = secondary;
  static const accentForeground = Color(0xFFFFFFFF);
  static const destructive = Color(0xFFD9534F);
  static const destructiveForeground = Colors.white;
  static const warning = Color(0xFFE9B949);
  static const info = Color(0xFF4A90E2);
  static const border = Color(0xFFDCEAD2);
  static const inputBackground = stone200;
  static const switchBackground = stone400;
  static const radius = 10.0; // 0.625rem
}

ThemeData buildChowTheme() {
  const seed = ChowCozy.primary;
  final baseTextTheme = GoogleFonts.juaTextTheme();

  return ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.jua().fontFamily,
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
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: ChowCozy.background,
      foregroundColor: ChowCozy.foreground,
      titleTextStyle: GoogleFonts.jua(
        color: ChowCozy.foreground,
        fontSize: 18,
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
        borderSide: const BorderSide(color: ChowCozy.primary, width: 2),
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
        textStyle: GoogleFonts.jua(fontSize: 16),
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
        textStyle: GoogleFonts.jua(fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ChowCozy.secondary,
        textStyle: GoogleFonts.jua(fontSize: 16),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: ChowCozy.card,
      selectedColor: ChowCozy.primaryLight,
      side: const BorderSide(color: ChowCozy.border),
      labelStyle: GoogleFonts.jua(color: ChowCozy.foreground),
      secondarySelectedColor: ChowCozy.primaryLight,
      checkmarkColor: ChowCozy.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    ),
    textTheme: baseTextTheme.apply(
      bodyColor: ChowCozy.foreground,
      displayColor: ChowCozy.foreground,
    ),
  );
}
