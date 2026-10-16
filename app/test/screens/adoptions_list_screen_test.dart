import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/api/api_client.dart';
import 'package:furescue_app/api/config.dart';
import 'package:furescue_app/screens/adoptions_list_screen.dart';
import 'package:furescue_app/screens/animal_detail_screen.dart';
import 'package:furescue_app/screens/animals_list_screen.dart';
import 'package:http/http.dart' as http;

import '../support/http_json.dart';
import '../support/signed_in.dart';

void main() {
  const config = ApiConfig(baseUrl: 'http://127.0.0.1:8000');
  const phone = Size(360, 740);

  testWidgets('browse animals pushes the catalog and back returns', (
    tester,
  ) async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        return jsonResponse(okEnvelope([]));
      }),
    );

    await pumpSignedIn(tester, const AdoptionsListScreen(), api, size: phone);
    await tester.pumpAndSettle();

    expect(find.text('No applications here yet'), findsOneWidget);
    await tester.tap(find.text('Browse animals'));
    await tester.pumpAndSettle();

    expect(find.byType(AnimalsListScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Browse'), findsOneWidget);
    expect(find.text('Dogs'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(AnimalsListScreen), findsNothing);
    expect(find.text('My adoptions'), findsOneWidget);
  });

  testWidgets('view animal opens detail without throwing on the first frame', (
    tester,
  ) async {
    final animalGate = Completer<http.Response>();
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) {
        if (request.url.path.contains('/animals/')) {
          return animalGate.future;
        }
        return Future.value(
          jsonResponse(
            okEnvelope([
              {
                'id': 'ad1',
                'animal_id': 'a1',
                'status': 'pending',
                'animal_name': 'Luna',
                'message': 'We have a quiet yard.',
                'created_at': '2020-01-15 08:00:00',
              },
            ]),
          ),
        );
      }),
    );

    await pumpSignedIn(tester, const AdoptionsListScreen(), api, size: phone);
    await tester.pumpAndSettle();
    expect(find.text('Luna'), findsOneWidget);
    expect(find.text('View animal'), findsOneWidget);

    await tester.tap(find.text('View animal'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.byType(AnimalDetailScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Animal'), findsOneWidget);

    animalGate.complete(
      jsonResponse(
        okEnvelope({
          'animal': {
            'id': 'a1',
            'name': 'Luna',
            'species': 'dog',
            'breed_type': 'aspin',
            'sex': 'female',
            'adoption_status': 'available',
          },
        }),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(AppBar, 'Luna'), findsOneWidget);
  });

  testWidgets('a long adoption note does not overflow at 360px', (tester) async {
    final note = 'Please call ${'soon ' * 30}${'x' * 80}';
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        return jsonResponse(
          okEnvelope([
            {
              'id': 'ad1',
              'animal_id': 'a1',
              'status': 'pending',
              'animal_name': 'City Veterinary ${'Name' * 20}',
              'message': note,
              'created_at': '2020-01-15 08:00:00',
            },
          ]),
        );
      }),
    );

    await pumpSignedIn(tester, const AdoptionsListScreen(), api, size: phone);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Please call'), findsOneWidget);
    expect(tester.getTopRight(find.textContaining('Please call')).dx, lessThanOrEqualTo(360));
  });

  testWidgets('an application with no animal stays on the list', (tester) async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        return jsonResponse(
          okEnvelope([
            {
              'id': 'ad1',
              'animal_id': '',
              'status': 'pending',
              'animal_name': null,
            },
          ]),
        );
      }),
    );

    await pumpSignedIn(tester, const AdoptionsListScreen(), api, size: phone);
    await tester.pumpAndSettle();
    await tester.tap(find.text('View animal'));
    await tester.pumpAndSettle();

    expect(find.byType(AnimalDetailScreen), findsNothing);
    expect(find.text('This application is not linked to an animal.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
