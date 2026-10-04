import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../api/media.dart';
import '../theme/tokens.dart';

/// Raster photos crop to fill; demo SVG portraits stay fully visible.
class MediaPhoto extends StatelessWidget {
  const MediaPhoto({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final resolvedFit = fit ?? (isSvgUrl(url) ? BoxFit.contain : BoxFit.cover);
    final fallback = Container(
      width: width,
      height: height,
      color: tokens.muted,
      alignment: Alignment.center,
      child: Icon(Icons.pets_outlined, color: tokens.jungle),
    );

    if (isSvgUrl(url)) {
      return SvgPicture.network(
        url,
        width: width,
        height: height,
        fit: resolvedFit,
        placeholderBuilder: (_) => fallback,
      );
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: resolvedFit,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
