import '../api/json_map.dart';

class Adoption {
  const Adoption({
    required this.id,
    required this.animalId,
    required this.status,
    this.animalName,
    this.message,
    this.rejectionReason,
    this.createdAt,
  });

  final String id;
  final String animalId;
  final String status;
  final String? animalName;
  final String? message;
  final String? rejectionReason;
  final String? createdAt;

  bool get canCancel => status == 'pending';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  factory Adoption.fromJson(Map<String, dynamic> json) {
    return Adoption(
      id: (json['id'] ?? '').toString(),
      animalId: (json['animal_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      animalName: asNullableString(json['animal_name']),
      message: asNullableString(json['message']),
      rejectionReason: asNullableString(json['rejection_reason']),
      createdAt: asNullableString(json['created_at']),
    );
  }
}
