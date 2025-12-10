import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  // Gunakan AuthService, bukan ApiService langsung
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _userRole;

  // Getter untuk UI
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get userRole => _userRole;

  /// Logic Auto Login saat aplikasi dibuka
  Future<bool> tryAutoLogin() async {
    final hasToken = await _authService.hasToken();
    if (!hasToken) {
      return false;
    }

    // Ambil role yang tersimpan
    _userRole = await _authService.getSavedRole();
    _isAuthenticated = true;
    notifyListeners();
    return true;
  }

  /// Logic Login
  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Panggil AuthService
      final User user = await _authService.login(username, password);

      // Update State di Memori
      _isAuthenticated = true;
      _userRole = user.role;

      print("Login Sukses: ${user.username} sebagai $_userRole");

    } catch (e) {
      _isAuthenticated = false;
      print("Login Error di Provider: $e");
      rethrow; // Lempar ke UI (Login Page) agar muncul Snackbar
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logic Logout
  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _userRole = null;
    notifyListeners();
  }
}