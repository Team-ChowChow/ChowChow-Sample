class RecipeShareContent {
  const RecipeShareContent._();

  static String shareText({
    required String title,
    required String subtitle,
    required String description,
  }) {
    final normalizedSubtitle = _singleLine(subtitle);
    final normalizedDescription = _singleLine(description);
    final summary = normalizedDescription.length > 180
        ? '${normalizedDescription.substring(0, 180)}…'
        : normalizedDescription;
    return [
      '🐾 ${title.trim()}',
      if (normalizedSubtitle.isNotEmpty) normalizedSubtitle,
      if (summary.isNotEmpty && summary != normalizedSubtitle) summary,
      '',
      '멍냥밥상에서 레시피를 확인해 보세요 🐾',
    ].join('\n');
  }

  static String _singleLine(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
