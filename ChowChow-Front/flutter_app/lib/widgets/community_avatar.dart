import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/chow_theme.dart';

class CommunityAvatar extends StatelessWidget {
  const CommunityAvatar({
    super.key,
    required this.radius,
    this.imageUrl,
    this.backgroundColor = ChowCozy.stone100,
  });

  final double radius;
  final String? imageUrl;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: url != null && url.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, _) => _DefaultAvatar(size: radius),
              errorWidget: (_, _, _) => _DefaultAvatar(size: radius),
            )
          : _DefaultAvatar(size: radius),
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ChowCozy.stone100,
      child: Center(
        child: Icon(
          Icons.person,
          size: size,
          color: ChowCozy.stone500,
        ),
      ),
    );
  }
}
