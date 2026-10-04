import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/api/api_exception.dart';
import 'package:furescue_app/api/envelope.dart';
import 'package:furescue_app/api/json_map.dart';

void main() {
  test('parses a PHP Response::success envelope', () {
    final envelope = Envelope.fromJson({
      'success': true,
      'data': {
        'user': {'id': 'u1', 'role': 'resident'},
        'tokens': {
          'access_token': 'access',
          'refresh_token': 'refresh',
        },
      },
      'error': null,
    });
    expect(envelope.success, isTrue);
    expect(envelope.error, isNull);
    expect(envelope.requireMap()['tokens'], isA<Map>());
  });

  test('parses INVALID_CREDENTIALS from AuthController', () {
    final envelope = Envelope.fromJson({
      'success': false,
      'data': null,
      'error': {
        'code': 'INVALID_CREDENTIALS',
        'message': 'Email or password is incorrect',
      },
    });
    expect(envelope.success, isFalse);
    expect(envelope.error?.code, 'INVALID_CREDENTIALS');
    expect(envelope.error?.message, 'Email or password is incorrect');
  });

  test('parses ACCOUNT_PENDING from AuthController', () {
    final envelope = Envelope.fromJson({
      'success': false,
      'data': null,
      'error': {
        'code': 'ACCOUNT_PENDING',
        'message': 'Account is not active (status: pending)',
      },
    });
    expect(envelope.error?.code, 'ACCOUNT_PENDING');
  });

  test('requireList reads paginated data arrays', () {
    final envelope = Envelope.fromJson({
      'success': true,
      'data': [
        {'id': 'r1'},
        {'id': 'r2'},
      ],
      'error': null,
      'meta': {'page': 1, 'per_page': 50, 'total': 2},
    });
    expect(envelope.requireList(), hasLength(2));
  });

  test('requireMap throws when data is not an object', () {
    final envelope = Envelope.fromJson({
      'success': true,
      'data': 'not-an-object',
      'error': null,
    });
    expect(envelope.requireMap, throwsFormatException);
  });

  test('asJsonMap throws ApiException BAD_RESPONSE for a non-object', () {
    expect(
      () => asJsonMap('not-an-object'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'BAD_RESPONSE'),
      ),
    );
  });
}
