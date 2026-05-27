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

  @override
  Widget build(BuildContext context) {
    final child = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, _) => Container(
        color: const Color(0xFFF3F4F6),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, _, _) => Container(
        color: const Color(0xFFF3F4F6),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF)),
      ),
    );
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
