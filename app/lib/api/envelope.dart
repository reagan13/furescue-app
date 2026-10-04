/// PHP `Response::success` / `Response::error` body.
class Envelope {
  const Envelope({required this.success, this.data, this.error});

  final bool success;
  final Object? data;
  final EnvelopeError? error;

  factory Envelope.fromJson(Map<String, dynamic> json) {
    final rawError = json['error'];
    return Envelope(
      success: json['success'] == true,
      data: json['data'],
      error: rawError is Map<String, dynamic>
          ? EnvelopeError.fromJson(rawError)
          : null,
    );
  }

  Map<String, dynamic> requireMap() {
    final value = data;
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    throw const FormatException('Expected object data in API envelope');
  }

  List<Map<String, dynamic>> requireList() {
    final value = data;
    if (value is! List) {
      throw const FormatException('Expected list data in API envelope');
    }
    return [
      for (final item in value)
        if (item is Map<String, dynamic>)
          item
        else if (item is Map)
          item.cast<String, dynamic>(),
    ];
  }
}

class EnvelopeError {
  const EnvelopeError({required this.code, required this.message});

  final String code;
  final String message;

  factory EnvelopeError.fromJson(Map<String, dynamic> json) {
    return EnvelopeError(
      code: (json['code'] ?? 'ERROR').toString(),
      message: (json['message'] ?? 'Request failed').toString(),
    );
  }
}
