import 'package:flutter/material.dart';

import 'chow_theme.dart';

class RoomVisualStyle {
  const RoomVisualStyle({
    required this.wallColors,
    required this.floorColor,
    required this.accentColor,
    required this.label,
    this.imagePath,
  });

  final List<Color> wallColors;
  final Color floorColor;
  final Color accentColor;
  final String label;

  /// 구매/장착하면 캐릭터 화면 배경 전체를 덮는 일러스트 이미지.
  /// null이면 기존처럼 wallColors/floorColor 그라디언트만 쓴다.
  final String? imagePath;
}

RoomVisualStyle roomVisualFor(String? itemKey) {
  return switch (itemKey) {
    'room_sky' => const RoomVisualStyle(
      wallColors: [Color(0xFFDDF4FF), Color(0xFFF3FBFF)],
      floorColor: Color(0xFFD9C5A5),
      accentColor: Color(0xFF38A5DB),
      label: '궁전',
      imagePath: 'assets/images/themes/theme_palace.png',
    ),
    'room_forest' => const RoomVisualStyle(
      wallColors: [Color(0xFFDDF4DE), Color(0xFFF7FBEE)],
      floorColor: Color(0xFFD6C09A),
      accentColor: Color(0xFF5A9C68),
      label: '크리스마스',
      imagePath: 'assets/images/themes/theme_christmas.png',
    ),
    'room_night' => const RoomVisualStyle(
      wallColors: [Color(0xFF24324A), Color(0xFF4D5E7D)],
      floorColor: Color(0xFF493D51),
      accentColor: Color(0xFFF4C95D),
      label: '별빛 캠핑',
      imagePath: 'assets/images/themes/theme_camping.png',
    ),
    'room_summer' => const RoomVisualStyle(
      wallColors: [Color(0xFFFFE8B0), Color(0xFFFFF6E0)],
      floorColor: Color(0xFFF2C879),
      accentColor: Color(0xFFFF9F43),
      label: '여름날 방',
      imagePath: 'assets/images/themes/theme_summer.png',
    ),
    _ => const RoomVisualStyle(
      wallColors: [ChowCozy.stone300, ChowCozy.stone50],
      floorColor: Color(0xFFE8CDA8),
      accentColor: ChowCozy.stone500,
      label: '햇살 가득한 방',
    ),
  };
}

class ProfileFrameVisual {
  const ProfileFrameVisual({
    required this.colors,
    required this.shadowColor,
    required this.label,
  });

  final List<Color> colors;
  final Color shadowColor;
  final String label;
}

ProfileFrameVisual profileFrameVisualFor(String? itemKey) {
  return switch (itemKey) {
    'frame_mint' => const ProfileFrameVisual(
      colors: [Color(0xFF6EE7B7), Color(0xFF10B981)],
      shadowColor: Color(0x6610B981),
      label: '민트 리프',
    ),
    'frame_royal' => const ProfileFrameVisual(
      colors: [Color(0xFFFFE082), Color(0xFFF59E0B), Color(0xFFFFF1B8)],
      shadowColor: Color(0x88F59E0B),
      label: '로열 골드',
    ),
    _ => const ProfileFrameVisual(
      colors: [Color(0xFFFB923C), Color(0xFFF97316)],
      shadowColor: Color(0x66F97316),
      label: '오렌지 링',
    ),
  };
}
