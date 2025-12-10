import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _shouldShowSplash = false; // State baru untuk Splash Screen
  String? _userRole;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get shouldShowSplash => _shouldShowSplash;
  String? get userRole => _userRole;

  Future<bool> tryAutoLogin() async {
    final hasToken = await _authService.hasToken();
    if (!hasToken) return false;

    _userRole = await _authService.getSavedRole();
    _isAuthenticated = true;
    _shouldShowSplash = false; // Auto login tidak perlu splash sukses
    notifyListeners();
    return true;
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final User user = await _authService.login(username, password);

      _isAuthenticated = true;
      _userRole = user.role;
      _shouldShowSplash = true; // Trigger Splash Screen setelah login manual sukses

    } catch (e) {
      _isAuthenticated = false;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi untuk mematikan splash screen setelah animasi selesai
  void completeSplash() {
    _shouldShowSplash = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _userRole = null;
    _shouldShowSplash = false;
    notifyListeners();
  }
}