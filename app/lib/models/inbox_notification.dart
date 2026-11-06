import '../api/json_map.dart';

class InboxNotification {
  const InboxNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.isRead,
    this.relatedType,
    this.relatedId,
    this.createdAt,
  });

  final String id;
  final String type;
  final String message;
  final bool isRead;
  final String? relatedType;
  final String? relatedId;
  final String? createdAt;

  factory InboxNotification.fromJson(Map<String, dynamic> json) {
    return InboxNotification(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      isRead: asBool(json['is_read']),
      relatedType: asNullableString(json['related_type']),
      relatedId: asNullableString(json['related_id']),
      createdAt: asNullableString(json['created_at']),
    );
  }

  String get kindLabel {
    switch (relatedType) {
      case 'report':
        return 'Report';
      case 'adoption':
        return 'Adoption';
      case 'case':
        return 'Case';
      case 'listing':
      case 'adoption_listing':
        return 'Listing';
      default:
        return 'Update';
    }
  }
}
