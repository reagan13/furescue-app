/// Turns a module `content_body` into readable paragraphs.
///
/// The API stores one HTML or plain-text string. Tags become breaks.
/// A missing body is an empty list, not an error.
List<String> lessonParagraphs(String? raw) {
  if (raw == null) {
    return const [];
  }
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return const [];
  }
  if (!trimmed.contains('<')) {
    return _cleanParts(trimmed.split(RegExp(r'\n+')));
  }
  var text = trimmed.replaceAll('\r\n', '\n');
  text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  text = text.replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n');
  text = text.replaceAll(RegExp(r'<[^>]*>'), '');
  text = _decodeBasicEntities(text);
  return _cleanParts(text.split(RegExp(r'\n\s*\n')));
}

/// First paragraph, shortened for a course card. Empty when the payload has no body.
String lessonExcerpt(String? raw, {int maxChars = 140}) {
  final paragraphs = lessonParagraphs(raw);
  if (paragraphs.isEmpty) {
    return '';
  }
  final first = paragraphs.first;
  if (first.length <= maxChars) {
    return first;
  }
  final slice = first.substring(0, maxChars);
  final lastSpace = slice.lastIndexOf(' ');
  final cut = lastSpace > 40 ? slice.substring(0, lastSpace) : slice;
  return '${cut.trimRight()}…';
}

List<String> _cleanParts(List<String> parts) {
  return [
    for (final part in parts)
      if (part.replaceAll(RegExp(r'[ \t]+'), ' ').trim().isNotEmpty)
        part.replaceAll(RegExp(r'[ \t]+'), ' ').replaceAll('\n', ' ').trim(),
  ];
}

String _decodeBasicEntities(String input) {
  return input
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&');
}
