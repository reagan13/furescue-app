import 'package:flutter/material.dart';

import '../api/config.dart';
import '../api/media.dart';
import '../theme/tokens.dart';
import 'media_photo.dart';

/// Full-width photo for a report card or detail. Missing photos stay a
/// calm block instead of a broken image.
class ReportFeedImage extends StatelessWidget {
  const ReportFeedImage({super.key, this.path, this.height = 240});

  /// Storage path or absolute URL from `photo_urls`.
  final String? path;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final raw = path?.trim();
    if (raw == null || raw.isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        color: tokens.muted,
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined, color: tokens.jungle2, size: 40),
      );
    }
    final url = resolveMediaUrl(ApiConfig.current, raw);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: MediaPhoto(
        url: url,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  }
}
