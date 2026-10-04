import 'api_exception.dart';

Map<String, dynamic> asJsonMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  throw const ApiException(
    code: 'BAD_RESPONSE',
    message: 'Unexpected response from the API.',
  );
}

List<Map<String, dynamic>> asJsonMapList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return [
    for (final item in value)
      if (item is Map<String, dynamic>)
        item
      else if (item is Map)
        item.cast<String, dynamic>(),
  ];
}

String? asNullableString(Object? value) {
  if (value == null) {
    return null;
  }
  final text = value.toString();
  return text.isEmpty ? null : text;
}

int asInt(Object? value, [int fallback = 0]) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool asBool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value == 1 || value == '1' || value == 'true') {
    return true;
  }
  return false;
}
