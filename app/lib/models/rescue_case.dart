import '../api/json_map.dart';
import '../api/media.dart';

class RescueCase {
  const RescueCase({
    required this.id,
    required this.status,
    this.reportId,
    this.animalDescription,
    this.addressText,
    this.createdAt,
    this.updatedAt,
    this.resolutionNotes,
    this.resolutionPhotos = const [],
    this.reportPhotos = const [],
    this.animalId,
  });

  final String id;
  final String status;
  final String? reportId;
  final String? animalDescription;
  final String? addressText;
  final String? createdAt;
  final String? updatedAt;
  final String? resolutionNotes;
  final List<String> resolutionPhotos;
  final List<String> reportPhotos;
  final String? animalId;

  factory RescueCase.fromJson(Map<String, dynamic> json) {
    final report = json['report'];
    Map<String, dynamic>? reportMap;
    if (report is Map<String, dynamic>) {
      reportMap = report;
    } else if (report is Map) {
      reportMap = report.cast<String, dynamic>();
    }
    return RescueCase(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      reportId: asNullableString(json['report_id']),
      animalDescription:
          asNullableString(json['animal_description']) ??
          asNullableString(reportMap?['animal_description']),
      addressText:
          asNullableString(json['address_text']) ??
          asNullableString(reportMap?['address_text']),
      createdAt: asNullableString(json['created_at']),
      updatedAt: asNullableString(json['updated_at']),
      resolutionNotes: asNullableString(json['resolution_notes']),
      resolutionPhotos: parseUrlList(
        json['resolution_photos'] ?? json['proof'],
      ),
      reportPhotos: parseUrlList(
        json['photo_urls'] ?? reportMap?['photo_urls'],
      ),
      animalId: asNullableString(json['animal_id']),
    );
  }

  RescueCase mergeReport({
    String? animalDescription,
    String? addressText,
    List<String>? photos,
  }) {
    return RescueCase(
      id: id,
      status: status,
      reportId: reportId,
      animalDescription: this.animalDescription ?? animalDescription,
      addressText: this.addressText ?? addressText,
      createdAt: createdAt,
      updatedAt: updatedAt,
      resolutionNotes: resolutionNotes,
      resolutionPhotos: resolutionPhotos,
      reportPhotos: reportPhotos.isNotEmpty
          ? reportPhotos
          : (photos ?? const []),
      animalId: animalId,
    );
  }

  bool get canRespond => status == 'assigned';
  bool get canAddProof => status == 'in_progress';

  String get statusLabel {
    switch (status) {
      case 'open':
        return 'Open';
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In progress';
      case 'resolved':
        return 'Resolved';
      default:
        return status;
    }
  }
}

class CaseActivity {
  const CaseActivity({required this.action, this.notes, this.createdAt});

  final String action;
  final String? notes;
  final String? createdAt;

  factory CaseActivity.fromJson(Map<String, dynamic> json) {
    return CaseActivity(
      action: (json['action'] ?? '').toString(),
      notes: asNullableString(json['notes']),
      createdAt: asNullableString(json['created_at']),
    );
  }
}
