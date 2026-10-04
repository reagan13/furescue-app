import 'package:geolocator/geolocator.dart';

import '../api/api_exception.dart';

class ReportPin {
  const ReportPin({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

Future<ReportPin> readCurrentReportPin() async {
  final enabled = await Geolocator.isLocationServiceEnabled();
  if (!enabled) {
    throw const ApiException(
      code: 'LOCATION',
      message: 'Turn on location services to pin this report.',
    );
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw const ApiException(
      code: 'LOCATION',
      message: 'Location permission is required to submit a report.',
    );
  }
  final pos = await Geolocator.getCurrentPosition();
  return ReportPin(latitude: pos.latitude, longitude: pos.longitude);
}
