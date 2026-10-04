/// `User::toArray()` from the PHP API (no password hash).
class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.accountStatus,
    this.authProvider,
    this.phoneNumber,
    this.address,
    this.profilePhotoUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final String accountStatus;
  final String? authProvider;
  final String? phoneNumber;
  final String? address;
  final String? profilePhotoUrl;

  bool get isAdmin => role == 'admin';
  bool get isRescuer => role == 'rescuer';
  bool get isResident => role == 'resident';
  bool get isActive => accountStatus == 'active';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      accountStatus: (json['account_status'] ?? '').toString(),
      authProvider: json['auth_provider']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      address: json['address']?.toString(),
      profilePhotoUrl: json['profile_photo_url']?.toString(),
    );
  }
}
