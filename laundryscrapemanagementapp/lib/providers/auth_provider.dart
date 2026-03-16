import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authService = AuthService();
      final res = await authService.login(email, password);
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(data['user']);
        _token = data['session']['access_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('staff_token', _token!);
        await prefs.setString('staff_user', jsonEncode(_currentUser!.toJson()));
        return true;
      } else {
        _error = res['error'] ?? 'Login failed';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      if (_token != null) {
        await AuthService(token: _token).logout(_token!);
      }
    } catch (_) {}
    _currentUser = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('staff_token');
    await prefs.remove('staff_user');
    notifyListeners();
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('staff_token');
    final savedUser = prefs.getString('staff_user');

    if (savedToken == null) return;

    _token = savedToken;
    if (savedUser != null) {
      _currentUser = UserModel.fromJson(jsonDecode(savedUser));
    }

    try {
      _currentUser = await AuthService().getMe(savedToken);
      notifyListeners();
    } catch (_) {
      _token = null;
      _currentUser = null;
      await prefs.remove('staff_token');
      await prefs.remove('staff_user');
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
