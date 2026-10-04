import '../api/json_map.dart';
import '../api/media.dart';

class Report {
  const Report({
    required this.id,
    required this.status,
    required this.animalDescription,
    this.addressText,
    this.createdAt,
    this.latitude,
    this.longitude,
    this.validationStatus,
    this.photoUrls = const [],
  });

  final String id;
  final String status;
  final String animalDescription;
  final String? addressText;
  final String? createdAt;
  final double? latitude;
  final double? longitude;
  final String? validationStatus;
  final List<String> photoUrls;

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      animalDescription: (json['animal_description'] ?? '').toString(),
      addressText: asNullableString(json['address_text']),
      createdAt: asNullableString(json['created_at']),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      validationStatus: asNullableString(json['validation_status']),
      photoUrls: parseUrlList(json['photo_urls']),
    );
  }

  bool get isFlaggedDuplicate => validationStatus == 'flagged_duplicate';

  String get statusLabel {
    switch (status) {
      case 'pending_verification':
        return 'Pending verification';
      case 'verified':
        return 'Verified';
      case 'dismissed':
        return 'Dismissed';
      default:
        return status;
    }
  }

  static double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }
}
