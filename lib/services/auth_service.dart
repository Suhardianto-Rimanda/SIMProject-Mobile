import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Kunci untuk SharedPreferences
  static const String _tokenKey = 'jwt_token';
  static const String _roleKey = 'user_role';
  static const String _usernameKey = 'username';

  /// Melakukan Login ke Backend
  /// Mengembalikan object [User] jika berhasil
  Future<User> login(String username, String password) async {
    try {
      // 1. Kirim data ke endpoint /auth/login
      final response = await _apiService.post(AppConstants.loginEndpoint, {
        'username': username,
        'password': password,
      });

      // 2. Parsing JSON menjadi Model User
      // Response Flask kamu: { "access_token": "...", "user": { "username": "...", "role": "..." } }
      final user = User.fromJson(response);

      // 3. Simpan Sesi ke HP (Storage)
      await _saveSession(user);

      return user;
    } catch (e) {
      // Error akan diteruskan ke Provider untuk ditampilkan di UI
      rethrow;
    }
  }

  /// Logout: Hapus sesi lokal & request logout ke backend (optional)
  Future<void> logout() async {
    // Optional: Panggil endpoint logout backend agar token di-blacklist
    try {
      await _apiService.post('/auth/logout', {});
    } catch (e) {
      print("Logout backend warning: $e"); // Abaikan jika gagal koneksi saat logout
    }

    // Wajib: Hapus data di HP
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Menyimpan data penting ke SharedPreferences
  Future<void> _saveSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user.accessToken != null) {
      await prefs.setString(_tokenKey, user.accessToken!);
    }
    await prefs.setString(_roleKey, user.role);
    await prefs.setString(_usernameKey, user.username);
  }

  /// Mengambil Role user yang tersimpan (untuk Auto Login)
  Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  /// Cek apakah ada token
  Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }
}