import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/auth_tokens.dart';
import '../models/user.dart';
import 'session_store.dart';

/// JWT session: login / register / refresh + GET /users/me for role.
class AuthSession extends ChangeNotifier {
  AuthSession({required this.api, required this.store}) {
    api.onRefresh = refreshAccess;
  }

  final ApiClient api;
  final SessionStore store;

  bool booting = true;
  bool busy = false;
  User? user;
  AuthTokens? tokens;
  String dutyStatus = 'off_duty';

  bool get isOnDuty => dutyStatus == 'on_duty';

  bool get isSignedIn => tokens != null && user != null && user!.isActive;

  Future<void> restore() async {
    tokens = await store.read();
    api.accessToken = tokens?.accessToken;
    if (tokens == null) {
      booting = false;
      notifyListeners();
      return;
    }
    try {
      user = await _fetchMe();
    } catch (_) {
      await _clearLocal();
    } finally {
      booting = false;
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle(String idToken) async {
    await _run(() async {
      final data = await api.post(
        '/api/v1/auth/google',
        auth: false,
        body: {'id_token': idToken},
      );
      await _acceptTokens(data);
      user = await _fetchMe();
    });
  }

  Future<void> login({required String email, required String password}) async {
    await _run(() async {
      final data = await api.post(
        '/api/v1/auth/login',
        auth: false,
        body: {'email': email.trim(), 'password': password},
      );
      await _acceptTokens(data);
      user = await _fetchMe();
    });
  }

  /// Null on success. A message if the account is pending (rescuer applicant).
  Future<String?> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
    String? address,
  }) async {
    return _run(() async {
      final body = <String, dynamic>{
        'full_name': fullName.trim(),
        'email': email.trim(),
        'password': password,
        'role': role,
      };
      final phone = phoneNumber?.trim() ?? '';
      final addr = address?.trim() ?? '';
      if (phone.isNotEmpty) {
        body['phone_number'] = phone;
      }
      if (addr.isNotEmpty) {
        body['address'] = addr;
      }

      final data = await api.post(
        '/api/v1/auth/register',
        auth: false,
        body: body,
      );
      final created = User.fromJson(_asMap(data['user']));
      if (!created.isActive) {
        return 'Your account needs admin approval before you can sign in.';
      }
      await _acceptTokens(data);
      user = await _fetchMe();
      return null;
    });
  }

  Future<String?> refreshAccess() async {
    final refresh = tokens?.refreshToken;
    if (refresh == null || refresh.isEmpty) {
      return null;
    }
    try {
      final data = await api.post(
        '/api/v1/auth/refresh',
        auth: false,
        body: {'refresh_token': refresh},
      );
      tokens = AuthTokens(
        accessToken: (data['access_token'] ?? '').toString(),
        refreshToken: refresh,
      );
      api.accessToken = tokens!.accessToken;
      if (data['user'] is Map) {
        user = User.fromJson(_asMap(data['user']));
      }
      await store.write(tokens!);
      return tokens!.accessToken;
    } on ApiException {
      return null;
    }
  }

  Future<void> logout() async {
    await _clearLocal();
    notifyListeners();
  }

  void applyUser(User next) {
    user = next;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    user = await _fetchMe();
    notifyListeners();
  }

  Future<void> setDuty(String status) async {
    final id = user?.id;
    if (id == null || id.isEmpty) {
      throw const ApiException(
        code: 'NO_USER',
        message: 'Sign in again to change duty status.',
      );
    }
    final data = await api.patch(
      '/api/v1/rescuers/$id/duty',
      body: {'status': status},
    );
    dutyStatus = (data['duty_status'] ?? status).toString();
    notifyListeners();
  }

  Future<User> _fetchMe() async {
    final data = await api.get('/api/v1/users/me');
    final map = _asMap(data['user']);
    final next = User.fromJson(map);
    if (next.isRescuer) {
      final duty = (map['duty_status'] ?? '').toString();
      if (duty == 'on_duty' || duty == 'off_duty') {
        dutyStatus = duty;
      }
    } else {
      dutyStatus = 'off_duty';
    }
    return next;
  }

  Future<void> _acceptTokens(Map<String, dynamic> data) async {
    final raw = data['tokens'];
    final map = _asMap(raw);
    tokens = AuthTokens(
      accessToken: (map['access_token'] ?? '').toString(),
      refreshToken: (map['refresh_token'] ?? '').toString(),
    );
    if (!tokens!.isComplete) {
      throw const ApiException(
        code: 'BAD_RESPONSE',
        message: 'Login did not return access and refresh tokens.',
      );
    }
    api.accessToken = tokens!.accessToken;
    await store.write(tokens!);
  }

  Future<void> _clearLocal() async {
    tokens = null;
    user = null;
    dutyStatus = 'off_duty';
    api.accessToken = null;
    await store.clear();
  }

  Future<T> _run<T>(Future<T> Function() work) async {
    busy = true;
    notifyListeners();
    try {
      return await work();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    throw const ApiException(
      code: 'BAD_RESPONSE',
      message: 'Expected an object in the API data payload.',
    );
  }
}
