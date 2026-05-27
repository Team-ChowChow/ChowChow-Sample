import 'package:flutter/material.dart';

/// 웹 앱 tailwind 오렌지/그레이 팔레트에 맞춤
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

ThemeData buildChowTheme() {
  const seed = ChowColors.orange500;
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      primary: ChowColors.orange500,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: ChowColors.gray50,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: ChowColors.gray800,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ChowColors.gray300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ChowColors.gray300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ChowColors.orange500, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: ChowColors.orange500,
        foregroundColor: Colors.white,
      ),
    ),
  );
}
