import 'package:flutter/material.dart';

import '../api/config.dart';
import '../api/media.dart';
import '../theme/tokens.dart';
import 'media_photo.dart';

class PhotoStrip extends StatelessWidget {
  const PhotoStrip({super.key, required this.urls, this.height = 160});

  final List<String> urls;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return const SizedBox.shrink();
    }
    final tokens = context.tokens;
    final config = ApiConfig.current;
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radius),
            child: MediaPhoto(
              url: resolveMediaUrl(config, urls[i]),
              width: height * 1.2,
              height: height,
            ),
          );
        },
      ),
    );
  }
}
