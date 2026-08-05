import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// React ImageWithFallback 과 동등: 로딩/에러 시 플레이스홀더
class ChowNetworkImage extends StatelessWidget {
  const ChowNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  String _resolveImageUrl(String url) {
    // 파일명만 있는 경우 (예: "character_group_2")
    if (!url.contains('/') && url.contains('character_group')) {
      return 'assets/images/characters/$url.png';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveImageUrl(url);

    final placeholder = Container(
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );

    final errorWidget = Container(
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF)),
    );

    final child = resolvedUrl.startsWith('assets/')
        ? Image.asset(
            resolvedUrl,
            fit: fit,
            errorBuilder: (_, __, ___) => errorWidget,
          )
        : CachedNetworkImage(
            imageUrl: resolvedUrl,
            fit: fit,
            placeholder: (_, _) => placeholder,
            errorWidget: (_, _, _) => errorWidget,
          );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
