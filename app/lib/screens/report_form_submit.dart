import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/json_map.dart';
import '../models/report.dart';

class SentReport {
  const SentReport({required this.report, this.photoError});

  final Report report;
  final String? photoError;
}

Future<SentReport> sendReport({
  required ApiClient api,
  required String description,
  required String address,
  required double latitude,
  required double longitude,
  required List<String> photoPaths,
}) async {
  final body = <String, dynamic>{
    'animal_description': description,
    'latitude': latitude,
    'longitude': longitude,
  };
  if (address.isNotEmpty) {
    body['address_text'] = address;
  }
  final data = await api.post('/api/v1/reports', body: body);
  final report = Report.fromJson(asJsonMap(data['report']));
  String? photoError;
  if (photoPaths.isNotEmpty) {
    try {
      await api.postMultipart(
        '/api/v1/reports/${report.id}/media',
        fieldName: 'photos[]',
        filePaths: photoPaths,
      );
    } on ApiException catch (e) {
      photoError = 'Report created, but photos failed: ${e.message}';
    }
  }
  return SentReport(report: report, photoError: photoError);
}
