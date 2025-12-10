import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/admin_dashboard_model.dart'; // Menggunakan model data yang sudah ada

class StaffProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // STATE DASHBOARD
  AdminDashboardModel? _dashboardData;
  bool _isLoadingDashboard = false;
  String? _errorMessage;

  AdminDashboardModel? get dashboardData => _dashboardData;
  bool get isLoadingDashboard => _isLoadingDashboard;
  String? get errorMessage => _errorMessage;

  // --- FETCH DASHBOARD ---
  // Asumsi: Backend mengizinkan role ini mengakses endpoint ini atau ada endpoint serupa
  Future<void> fetchDashboard() async {
    _isLoadingDashboard = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Ganti endpoint ini jika backend menyediakan endpoint khusus
      final response = await _apiService.get('/admin/dashboard');
      _dashboardData = AdminDashboardModel.fromJson(response);
    } catch (e) {
      print("Error fetch staff dashboard: $e");
      _errorMessage = e.toString();
    } finally {
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }
}