import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/api/api_client.dart';
import 'package:furescue_app/api/api_exception.dart';
import 'package:furescue_app/api/config.dart';

import '../support/http_json.dart';

void main() {
  const config = ApiConfig(baseUrl: 'http://127.0.0.1:8000');

  test('POST login returns token map from a success envelope', () async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/auth/login');
        expect(request.headers['authorization'], isNull);
        return jsonResponse(
          okEnvelope({
            'user': fixtureUser(role: 'resident'),
            'tokens': {
              'access_token': 'access-1',
              'refresh_token': 'refresh-1',
            },
          }),
        );
      }),
    );

    final data = await api.post(
      '/api/v1/auth/login',
      auth: false,
      body: {'email': 'juan@furescue.local', 'password': 'Password123!'},
    );
    expect(data['tokens'], isA<Map>());
    expect((data['tokens'] as Map)['access_token'], 'access-1');
  });

  test('throws ApiException on INVALID_CREDENTIALS', () async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        return jsonResponse(
          errorEnvelope('INVALID_CREDENTIALS', 'Email or password is incorrect'),
          status: 401,
        );
      }),
    );

    expect(
      () => api.post(
        '/api/v1/auth/login',
        auth: false,
        body: {'email': 'juan@furescue.local', 'password': 'nope'},
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          'INVALID_CREDENTIALS',
        ),
      ),
    );
  });

  test('sends Bearer token on authenticated GET', () async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        expect(request.headers['authorization'], 'Bearer access-1');
        return jsonResponse(
          okEnvelope({
            'user': fixtureUser(role: 'resident'),
          }),
        );
      }),
    )..accessToken = 'access-1';

    final data = await api.get('/api/v1/users/me');
    expect((data['user'] as Map)['role'], 'resident');
  });

  test('getList reads paginated report rows', () async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        return jsonResponse(
          okEnvelope([
            {'id': 'r1', 'animal_description': 'Aspin'},
          ]),
        );
      }),
    )..accessToken = 'access-1';

    final rows = await api.getList('/api/v1/reports/me?per_page=50');
    expect(rows, hasLength(1));
    expect(rows.first['id'], 'r1');
  });

  test('success HTTP with non-object data throws BAD_RESPONSE', () async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        return jsonResponse(okEnvelope('not-an-object'));
      }),
    )..accessToken = 'access-1';

    expect(
      () => api.get('/api/v1/users/me'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'BAD_RESPONSE')
            .having(
              (e) => e.message,
              'message',
              'Unexpected response from the API.',
            )
            .having((e) => e.status, 'status', 200),
      ),
    );
  });

  test('retries a 401 once with the refreshed bearer token', () async {
    var gets = 0;
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        gets++;
        if (gets == 1) {
          expect(request.headers['authorization'], 'Bearer access-1');
          return jsonResponse(
            errorEnvelope('UNAUTHENTICATED', 'expired'),
            status: 401,
          );
        }
        expect(request.headers['authorization'], 'Bearer access-2');
        return jsonResponse(
          okEnvelope({'user': fixtureUser(role: 'resident')}),
        );
      }),
    )..accessToken = 'access-1'
      ..onRefresh = () async => 'access-2';

    final data = await api.get('/api/v1/users/me');
    expect(gets, 2);
    expect((data['user'] as Map)['role'], 'resident');
    expect(api.accessToken, 'access-2');
  });
}
