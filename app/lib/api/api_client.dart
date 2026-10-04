import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'config.dart';
import 'envelope.dart';

/// Thin `/api/v1` client. Adds `Authorization: Bearer` when [accessToken] is set.
class ApiClient {
  ApiClient({this.config = ApiConfig.current, http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final ApiConfig config;
  final http.Client _http;

  String? accessToken;

  /// Called once after a 401. Return a new access token, or null to give up.
  Future<String?> Function()? onRefresh;

  Future<Map<String, dynamic>> get(String path) async {
    return _objectData(await _send('GET', path, auth: true));
  }

  Future<List<Map<String, dynamic>>> getList(String path) async {
    return _listData(await _send('GET', path, auth: true));
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    return _objectData(await _send('POST', path, body: body, auth: auth));
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _objectData(await _send('PATCH', path, body: body, auth: true));
  }

  /// Multipart POST. [fieldName] is the PHP file key (`photos[]`, `files[]`, `file`).
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fieldName,
    required List<String> filePaths,
    Map<String, String>? fields,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final files = <http.MultipartFile>[];
    for (final filePath in filePaths) {
      files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    }
    return _objectData(
      await _sendMultipart(path, files: files, fields: fields, timeout: timeout),
    );
  }

  Map<String, dynamic> _objectData(_ApiResult result) {
    try {
      return result.envelope.requireMap();
    } on FormatException {
      throw ApiException(
        code: 'BAD_RESPONSE',
        message: 'Unexpected response from the API.',
        status: result.status,
      );
    }
  }

  List<Map<String, dynamic>> _listData(_ApiResult result) {
    try {
      return result.envelope.requireList();
    } on FormatException {
      throw ApiException(
        code: 'BAD_RESPONSE',
        message: 'Unexpected response from the API.',
        status: result.status,
      );
    }
  }

  Future<_ApiResult> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required bool auth,
    bool retried = false,
  }) async {
    final request = http.Request(method, config.resolve(path));
    request.headers['Accept'] = 'application/json';
    request.headers['Content-Type'] = 'application/json; charset=utf-8';
    if (auth && accessToken != null && accessToken!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final http.StreamedResponse streamed;
    try {
      streamed = await _http.send(request).timeout(const Duration(seconds: 20));
    } catch (e) {
      throw ApiException(
        code: 'NETWORK',
        message:
            'Cannot reach the FuRescue API at ${config.baseUrl}. '
            'Use adb reverse or a LAN --dart-define=API_BASE_URL.',
      );
    }

    final raw = await streamed.stream.bytesToString();
    final status = streamed.statusCode;

    if (status == 401 && auth && !retried && onRefresh != null) {
      final next = await onRefresh!();
      if (next != null && next.isNotEmpty) {
        accessToken = next;
        return _send(method, path, body: body, auth: auth, retried: true);
      }
    }

    Envelope envelope;
    try {
      final decoded = raw.isEmpty ? <String, dynamic>{} : jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Non-object JSON');
      }
      envelope = Envelope.fromJson(decoded);
    } catch (_) {
      throw ApiException(
        code: 'BAD_RESPONSE',
        message: 'Unexpected response from the API ($status).',
        status: status,
      );
    }

    if (!envelope.success) {
      throw ApiException(
        code: envelope.error?.code ?? 'ERROR',
        message: envelope.error?.message ?? 'Request failed',
        status: status,
      );
    }

    return _ApiResult(envelope, status);
  }

  Future<_ApiResult> _sendMultipart(
    String path, {
    required List<http.MultipartFile> files,
    Map<String, String>? fields,
    required Duration timeout,
    bool retried = false,
  }) async {
    final request = http.MultipartRequest('POST', config.resolve(path));
    request.headers['Accept'] = 'application/json';
    if (accessToken != null && accessToken!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    if (fields != null) {
      request.fields.addAll(fields);
    }
    for (final file in files) {
      request.files.add(file);
    }

    final http.StreamedResponse streamed;
    try {
      streamed = await _http.send(request).timeout(timeout);
    } catch (e) {
      throw ApiException(
        code: 'NETWORK',
        message:
            'Cannot reach the FuRescue API at ${config.baseUrl}. '
            'Use adb reverse or a LAN --dart-define=API_BASE_URL.',
      );
    }

    final raw = await streamed.stream.bytesToString();
    final status = streamed.statusCode;

    if (status == 401 && !retried && onRefresh != null) {
      final next = await onRefresh!();
      if (next != null && next.isNotEmpty) {
        accessToken = next;
        return _sendMultipart(
          path,
          files: files,
          fields: fields,
          timeout: timeout,
          retried: true,
        );
      }
    }

    Envelope envelope;
    try {
      final decoded = raw.isEmpty ? <String, dynamic>{} : jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Non-object JSON');
      }
      envelope = Envelope.fromJson(decoded);
    } catch (_) {
      throw ApiException(
        code: 'BAD_RESPONSE',
        message: 'Unexpected response from the API ($status).',
        status: status,
      );
    }

    if (!envelope.success) {
      throw ApiException(
        code: envelope.error?.code ?? 'ERROR',
        message: envelope.error?.message ?? 'Request failed',
        status: status,
      );
    }

    return _ApiResult(envelope, status);
  }
}

class _ApiResult {
  const _ApiResult(this.envelope, this.status);

  final Envelope envelope;
  final int status;
}
