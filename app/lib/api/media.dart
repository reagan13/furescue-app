import 'dart:convert';

import 'config.dart';

/// PHP stores photo lists as JSON arrays or a JSON string.
List<String> parseUrlList(Object? value) {
  if (value == null) {
    return const [];
  }
  if (value is List) {
    return [
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
  if (value is String && value.trim().isNotEmpty) {
    final raw = value.trim();
    try {
      return parseUrlList(jsonDecode(raw));
    } catch (_) {
      return [raw];
    }
  }
  return const [];
}

String resolveMediaUrl(ApiConfig config, String path) {
  final trimmed = path.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return config.resolve(trimmed).toString();
}

bool isVideoUrl(String url) {
  final path = url.toLowerCase().split('?').first;
  return path.endsWith('.mp4') || path.endsWith('.webm');
}

bool isSvgUrl(String url) {
  final path = url.toLowerCase().split('?').first;
  return path.endsWith('.svg');
}

String stripHtml(String raw) {
  return raw
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
