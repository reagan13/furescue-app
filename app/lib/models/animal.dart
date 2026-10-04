import '../api/json_map.dart';
import '../api/media.dart';

class Animal {
  const Animal({
    required this.id,
    required this.species,
    required this.breedType,
    required this.sex,
    required this.adoptionStatus,
    this.name,
    this.ageEstimate,
    this.colorMarkings,
    this.description,
    this.photoUrls = const [],
    this.model3dUrl,
    this.photo360Set = const [],
    this.source,
  });

  final String id;
  final String species;
  final String breedType;
  final String sex;
  final String adoptionStatus;
  final String? name;
  final String? ageEstimate;
  final String? colorMarkings;
  final String? description;
  final List<String> photoUrls;
  final String? model3dUrl;
  final List<String> photo360Set;
  final String? source;

  String get displayName {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) {
      return n;
    }
    return 'Unnamed ${species.isEmpty ? 'animal' : species}';
  }

  String get statusLabel {
    switch (adoptionStatus) {
      case 'available':
        return 'Available';
      case 'pending':
        return 'Pending';
      case 'adopted':
        return 'Adopted';
      case 'not_listed':
        return 'Not listed';
      default:
        return adoptionStatus;
    }
  }

  bool get isAvailable => adoptionStatus == 'available';

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: (json['id'] ?? '').toString(),
      species: (json['species'] ?? '').toString(),
      breedType: (json['breed_type'] ?? '').toString(),
      sex: (json['sex'] ?? '').toString(),
      adoptionStatus: (json['adoption_status'] ?? '').toString(),
      name: asNullableString(json['name']),
      ageEstimate: asNullableString(json['age_estimate']),
      colorMarkings: asNullableString(json['color_markings']),
      description: asNullableString(json['description']),
      photoUrls: parseUrlList(json['photo_urls']),
      model3dUrl: asNullableString(json['model_3d_url']),
      photo360Set: parseUrlList(json['photo_360_set']),
      source: asNullableString(json['source']),
    );
  }
}
