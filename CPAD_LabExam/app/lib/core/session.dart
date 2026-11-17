import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';

/// Who is logged in. The role decides which home screen the app shows.
class Session extends ChangeNotifier {
  Session._();
  static final Session I = Session._();

  Json? user;
  bool restoring = true;

  String get role => user?['role'] as String? ?? '';
  int get userId => user?['id'] as int? ?? 0;
  String get name => user?['name'] as String? ?? '';

  Future<void> restore() async {
    await Api.I.loadBaseUrl();
    Api.I.onUnauthorized = () => logout();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      Api.I.token = token;
      try {
        user = (await Api.I.get('/auth/me'))['user'] as Json;
      } catch (_) {
        Api.I.token = null;
        user = null;
      }
    }
    restoring = false;
    notifyListeners();
  }

  /// Supabase Auth checks the password on the backend, which then returns the app token.
  Future<void> login(String email, String password) async {
    await _start(await Api.I.post('/auth/login', {'email': email, 'password': password}));
  }

  /// Creates the Supabase Auth account and profile. Returns a message when the email must be
  /// confirmed first (no login yet), or null when the user is now logged in.
  Future<String?> signup(Json details) async {
    final res = await Api.I.post('/auth/signup', details);
    if (res['needsConfirmation'] == true) return res['message'] as String? ?? 'Check your email, then log in.';
    await _start(res);
    return null;
  }

  Future<void> _start(Json res) async {
    Api.I.token = res['token'] as String;
    user = res['user'] as Json;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', Api.I.token!);
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    user = (await Api.I.get('/auth/me'))['user'] as Json;
    notifyListeners();
  }

  Future<void> logout() async {
    Api.I.token = null;
    user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }
}
