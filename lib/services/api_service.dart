// ... imports (sama seperti sebelumnya)
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  // ... (method _logRequest, _logResponse, _getHeaders, post, get SAMA SEPERTI SEBELUMNYA) ...
  // ... Copy paste bagian atas dari kode sebelumnya ...

  // --- TAMBAHAN METHOD PUT ---
  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    _logRequest('PUT', url.toString(), body: jsonEncode(body));
    final headers = await _getHeaders();

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 20));

      _logResponse(url.toString(), response);
      return _processResponse(response);
    } catch (e) {
      print('!!! ERROR PUT: $e');
      throw Exception('Gagal update data: $e');
    }
  }

  // --- TAMBAHAN METHOD DELETE ---
  Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    _logRequest('DELETE', url.toString());
    final headers = await _getHeaders();

    try {
      final response = await http.delete(url, headers: headers)
          .timeout(const Duration(seconds: 20));

      _logResponse(url.toString(), response);
      return _processResponse(response);
    } catch (e) {
      print('!!! ERROR DELETE: $e');
      throw Exception('Gagal hapus data: $e');
    }
  }

  // ... (method _processResponse SAMA SEPERTI SEBELUMNYA) ...
  // Sertakan kembali helper-helper private di sini

  // --- CODE DEBUGGING UTILS ---
  void _logRequest(String method, String url, {dynamic body}) {
    print('------------------------------------------------');
    print('[$method] Request ke: $url');
    if (body != null) print('Body: $body');
  }

  void _logResponse(String url, http.Response response) {
    print('[$url] Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('------------------------------------------------');
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');
    var headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'SIMProject-Mobile/1.0',
    };
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  // --- GET REQUEST ---
  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    _logRequest('GET', url.toString());
    final headers = await _getHeaders();
    try {
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 20));
      _logResponse(url.toString(), response);
      return _processResponse(response);
    } catch (e) { throw Exception('Gagal ambil data: $e'); }
  }

  // --- POST REQUEST ---
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    _logRequest('POST', url.toString(), body: jsonEncode(body));
    final headers = await _getHeaders();
    try {
      final response = await http.post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));
      _logResponse(url.toString(), response);
      return _processResponse(response);
    } catch (e) { throw Exception('Gagal kirim data: $e'); }
  }


  dynamic _processResponse(http.Response response) {
    dynamic body;
    try { body = jsonDecode(response.body); } catch (e) { throw Exception('Server Error: ${response.statusCode}'); }
    if (response.statusCode >= 200 && response.statusCode < 300) return body;
    else throw Exception(body['message'] ?? 'Terjadi kesalahan');
  }
}