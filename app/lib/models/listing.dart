import '../api/json_map.dart';

class Listing {
  const Listing({
    required this.id,
    required this.animalId,
    required this.status,
    this.reviewNotes,
    this.createdAt,
  });

  final String id;
  final String animalId;
  final String status;
  final String? reviewNotes;
  final String? createdAt;

  String get statusLabel {
    switch (status) {
      case 'pending_review':
        return 'In review';
      case 'approved':
        return 'Live';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  bool get isLive => status == 'pending_review' || status == 'approved';

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: (json['id'] ?? '').toString(),
      animalId: (json['animal_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      reviewNotes: asNullableString(json['review_notes']),
      createdAt: asNullableString(json['created_at']),
    );
  }
}
