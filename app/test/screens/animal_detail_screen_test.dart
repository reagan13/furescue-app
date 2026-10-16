import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/api/api_client.dart';
import 'package:furescue_app/api/config.dart';
import 'package:furescue_app/screens/animal_detail_screen.dart';
import 'package:http/http.dart' as http;

import '../support/http_json.dart';
import '../support/signed_in.dart';

void main() {
  const config = ApiConfig(baseUrl: 'http://127.0.0.1:8000');

  testWidgets('animal detail first frame does not throw while the animal is null', (
    tester,
  ) async {
    final gate = Completer<http.Response>();
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) => gate.future),
    );

    await pumpSignedIn(
      tester,
      const AnimalDetailScreen(animalId: 'a1'),
      api,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Animal'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('View in 3D'), findsNothing);

    gate.complete(jsonResponse(okEnvelope({'animal': _animalJson()})));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Luna'), findsWidgets);
    expect(find.text('No 3D profile uploaded yet.'), findsOneWidget);
    expect(find.text('Submit application'), findsOneWidget);
  });

  testWidgets('null animal fields render an unnamed animal', (tester) async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        return jsonResponse(
          okEnvelope({
            'animal': {
              'id': 'a-blank',
              'species': null,
              'breed_type': null,
              'sex': null,
              'adoption_status': null,
              'name': null,
              'age_estimate': null,
              'color_markings': null,
              'description': null,
              'photo_urls': null,
              'model_3d_url': null,
              'photo_360_set': null,
            },
          }),
        );
      }),
    );

    await pumpSignedIn(
      tester,
      const AnimalDetailScreen(animalId: 'a-blank'),
      api,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Unnamed animal'), findsWidgets);
    expect(find.text('Animal not found.'), findsNothing);
    expect(find.text('No 3D profile uploaded yet.'), findsOneWidget);
    expect(find.text('View in 3D'), findsNothing);
  });
}

Map<String, Object?> _animalJson() {
  return {
    'id': 'a1',
    'name': 'Luna',
    'species': 'dog',
    'breed_type': 'aspin',
    'sex': 'female',
    'adoption_status': 'available',
    'age_estimate': '2 years',
    'description': 'Calm around children.',
    'photo_urls': <String>[],
    'model_3d_url': null,
    'photo_360_set': <String>[],
  };
}
