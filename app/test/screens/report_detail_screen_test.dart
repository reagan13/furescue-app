import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/api/api_client.dart';
import 'package:furescue_app/api/config.dart';
import 'package:furescue_app/screens/report_detail_screen.dart';
import 'package:furescue_app/widgets/app_card.dart';
import 'package:furescue_app/widgets/pin_map.dart';

import '../support/http_json.dart';
import '../support/signed_in.dart';

void main() {
  const config = ApiConfig(baseUrl: 'http://127.0.0.1:8000');

  testWidgets('report detail groups photo, status, description, and map', (
    tester,
  ) async {
    final description = 'Injured aspin ${'near the chapel ' * 8}';
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        expect(request.url.path, contains('/reports/r1'));
        return jsonResponse(
          okEnvelope({
            'report': {
              'id': 'r1',
              'status': 'verified',
              'animal_description': description,
              'address_text': 'Dahican, City of Mati',
              'latitude': 6.95,
              'longitude': 126.21,
              'photo_urls': <String>[],
            },
          }),
        );
      }),
    );

    await pumpSignedIn(
      tester,
      const ReportDetailScreen(reportId: 'r1'),
      api,
      size: const Size(360, 740),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.textContaining('Injured aspin'), findsOneWidget);
    expect(find.text('Dahican, City of Mati'), findsOneWidget);
    expect(find.text('6.95000, 126.21000'), findsOneWidget);
    expect(find.byType(PinMap), findsOneWidget);
    expect(find.text('Message City Vet'), findsOneWidget);
    final mapTop = tester.getTopLeft(find.byType(PinMap)).dy;
    expect(tester.getTopLeft(find.text('Dahican, City of Mati')).dy, greaterThan(mapTop));
    expect(
      tester.getTopLeft(find.text('6.95000, 126.21000')).dy,
      greaterThan(tester.getTopLeft(find.text('Dahican, City of Mati')).dy),
    );

    final card = find.byType(AppCard);
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text('Verified')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.byType(PinMap)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('Message City Vet')),
      findsNothing,
    );
    expect(
      tester.getTopRight(find.textContaining('Injured aspin')).dx,
      lessThanOrEqualTo(360),
    );
  });

  testWidgets('a pin with no address still prints the coordinates', (
    tester,
  ) async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        return jsonResponse(
          okEnvelope({
            'report': {
              'id': 'r2',
              'status': 'pending_verification',
              'animal_description': 'Dog by the shore',
              'address_text': '   ',
              'latitude': 6.961,
              'longitude': 126.165,
              'photo_urls': <String>[],
            },
          }),
        );
      }),
    );

    await pumpSignedIn(
      tester,
      const ReportDetailScreen(reportId: 'r2'),
      api,
      size: const Size(360, 740),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.byType(PinMap), findsOneWidget);
    expect(find.text('6.96100, 126.16500'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('6.96100, 126.16500')).dy,
      greaterThan(tester.getTopLeft(find.byType(PinMap)).dy),
    );
    expect(tester.getTopRight(find.text('6.96100, 126.16500')).dx, lessThanOrEqualTo(360));
  });
}
