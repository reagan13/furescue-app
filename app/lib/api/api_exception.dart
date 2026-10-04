/// Failed `{ success, data, error }` envelope or a transport error.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.status = 0,
  });

  final String code;
  final String message;
  final int status;

  bool get isUnauthorized => status == 401 || code == 'UNAUTHENTICATED';

  bool get isPending => code == 'ACCOUNT_PENDING';

  @override
  String toString() => message;
}
