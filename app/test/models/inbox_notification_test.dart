import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/api/media.dart';
import 'package:furescue_app/models/inbox_notification.dart';
import 'package:furescue_app/models/rescue_case.dart';

void main() {
  test('notification kinds use the survey labels', () {
    InboxNotification row(String type) => InboxNotification.fromJson({
      'id': 'n1',
      'type': 'ping',
      'message': 'Hello',
      'is_read': 0,
      'related_type': type,
    });

    expect(row('report').kindLabel, 'Report');
    expect(row('adoption').kindLabel, 'Adoption');
    expect(row('case').kindLabel, 'Case');
    expect(row('adoption_listing').kindLabel, 'Listing');
    expect(row('other').kindLabel, 'Update');
  });

  test('a case payload keeps the report pin', () {
    final item = RescueCase.fromJson({
      'id': 'case-1',
      'status': 'assigned',
      'latitude': '6.95',
      'longitude': 126.21,
      'health': {
        'animal': {'name': 'Ligaya', 'species': 'dog'},
        'vaccinations': [
          {'name': 'Rabies', 'date_given': '2026-10-01'},
        ],
        'heart_rate_bpm': 90,
      },
    });

    expect(item.latitude, 6.95);
    expect(item.longitude, 126.21);
    expect(item.health?.animalName, 'Ligaya');
    expect(item.health?.vaccinations, ['Rabies · 2026-10-01']);
    expect(item.health?.heartRate, 90);
  });

  test('video urls are not treated as photos', () {
    expect(isVideoUrl('/uploads/reports/2026/10/clip.mp4'), isTrue);
    expect(isVideoUrl('/uploads/reports/2026/10/clip.webm?x=1'), isTrue);
    expect(isVideoUrl('/uploads/reports/2026/10/photo.jpg'), isFalse);
  });
}