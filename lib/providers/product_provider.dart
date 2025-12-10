import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';
import '../utils/constants.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> fetchMenu() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Request ke backend: /sales/menu
      final response = await _apiService.get(AppConstants.menuEndpoint);

      // Response backend formatnya: { "count": ..., "menu": [...] }
      final List<dynamic> menuList = response['menu'];

      _products = menuList.map((item) => Product.fromJson(item)).toList();

    } catch (e) {
      print("Error fetching menu: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}