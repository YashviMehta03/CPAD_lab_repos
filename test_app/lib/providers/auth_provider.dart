import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/auth_data.dart';

class AuthProvider extends ChangeNotifier {
  static const String _boxName = 'authBox';
  late Box<AuthData> _box;

  bool _isLoggedIn = false;
  AuthData? _currentUser;

  bool get isLoggedIn => _isLoggedIn;
  AuthData? get currentUser => _currentUser;
  String get displayName => _currentUser?.displayName ?? '';

  Future<void> init() async {
    _box = Hive.box<AuthData>(_boxName);
    if (_box.isNotEmpty) {
      _currentUser = _box.getAt(0);
      _isLoggedIn = _currentUser?.isLoggedIn ?? false;
    }
  }

  bool get hasAccount => _box.isNotEmpty;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> signUp({
    required String displayName,
    required String username,
    required String password,
  }) async {
    if (_box.isNotEmpty) return false; // Only one account allowed
    final hash = _hashPassword(password);
    final auth = AuthData(
      displayName: displayName,
      username: username,
      passwordHash: hash,
      isLoggedIn: true,
    );
    await _box.add(auth);
    _currentUser = auth;
    _isLoggedIn = true;
    notifyListeners();
    return true;
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    if (_box.isEmpty) return false;
    final stored = _box.getAt(0)!;
    final hash = _hashPassword(password);
    if (stored.username == username && stored.passwordHash == hash) {
      stored.isLoggedIn = true;
      await stored.save();
      _currentUser = stored;
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    if (_currentUser != null) {
      _currentUser!.isLoggedIn = false;
      await _currentUser!.save();
    }
    _isLoggedIn = false;
    notifyListeners();
  }
}
