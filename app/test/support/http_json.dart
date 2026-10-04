import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response jsonResponse(Object body, {int status = 200}) {
  return http.Response(
    jsonEncode(body),
    status,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}

Map<String, Object?> okEnvelope(Object? data) {
  return {'success': true, 'data': data, 'error': null};
}

Map<String, Object?> errorEnvelope(String code, String message) {
  return {
    'success': false,
    'data': null,
    'error': {'code': code, 'message': message},
  };
}

MockClient jsonClient(
  Future<http.Response> Function(http.Request request) handler,
) {
  return MockClient(handler);
}

Map<String, Object?> fixtureUser({
  required String role,
  String id = '11111111-1111-4111-8111-111111111111',
  String email = 'juan@furescue.local',
  String fullName = 'Juan Resident',
  String accountStatus = 'active',
}) {
  return {
    'id': id,
    'full_name': fullName,
    'email': email,
    'role': role,
    'account_status': accountStatus,
    'auth_provider': 'native',
    'phone_number': null,
    'address': null,
    'profile_photo_url': null,
  };
}
