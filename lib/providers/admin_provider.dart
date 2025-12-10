import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/admin_dashboard_model.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/recipe_model.dart';
import '../models/ingredient_model.dart';
import '../models/finance_model.dart';

class AdminProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // --- STATE DASHBOARD ---
  AdminDashboardModel? _dashboardData;
  bool _isLoadingDashboard = false;
  String? _errorMessage;
  AdminDashboardModel? get dashboardData => _dashboardData;
  bool get isLoadingDashboard => _isLoadingDashboard;
  String? get errorMessage => _errorMessage;

  // --- STATE USER MANAGEMENT ---
  List<User> _users = [];
  bool _isLoadingUsers = false;
  bool get isLoadingUsers => _isLoadingUsers;
  List<User> get users => _users;

  // --- STATE PRODUCT MANAGEMENT ---
  List<Product> _products = [];
  bool _isLoadingProducts = false;
  List<Product> get products => _products;
  bool get isLoadingProducts => _isLoadingProducts;

  // --- STATE INGREDIENT (BAHAN BAKU) ---
  List<Ingredient> _ingredients = [];
  bool _isLoadingIngredients = false;
  List<Ingredient> get ingredients => _ingredients;
  bool get isLoadingIngredients => _isLoadingIngredients;

  List<Recipe> _currentRecipes = [];
  bool _isLoadingRecipes = false;
  List<Recipe> get currentRecipes => _currentRecipes;
  bool get isLoadingRecipes => _isLoadingRecipes;

  // ==========================
  // DASHBOARD LOGIC
  // ==========================
  Future<void> fetchDashboard() async {
    _isLoadingDashboard = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/admin/dashboard');
      _dashboardData = AdminDashboardModel.fromJson(response);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }

  // ==========================
  // USER LOGIC
  // ==========================
  Future<void> fetchUsers() async {
    _isLoadingUsers = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/admin/users');
      final List<dynamic> list = response;
      _users = list.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      print("Error fetch users: $e");
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }
  Future<void> addUser(Map<String, dynamic> body) async {
    await _apiService.post('/admin/users', body);
    await fetchUsers();
  }
  Future<void> editUser(int id, Map<String, dynamic> body) async {
    await _apiService.put('/admin/users/$id', body);
    await fetchUsers();
  }
  Future<void> deleteUser(int userId) async {
    await _apiService.delete('/admin/users/$userId');
    _users.removeWhere((u) => u.id == userId);
    notifyListeners();
  }

  // ==========================
  // PRODUCT LOGIC
  // ==========================
  Future<void> fetchProducts() async {
    _isLoadingProducts = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/admin/products');
      final List<dynamic> list = response;
      _products = list.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print("Error fetch products: $e");
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }
  Future<void> addProduct(Map<String, dynamic> body) async {
    await _apiService.post('/admin/products', body);
    await fetchProducts();
  }
  Future<void> updateProduct(int id, Map<String, dynamic> body) async {
    await _apiService.put('/admin/products/$id', body);
    await fetchProducts();
  }
  Future<void> deleteProduct(int id) async {
    await _apiService.delete('/admin/products/$id');
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // ==========================
  // RECIPE LOGIC
  // ==========================
  Future<void> fetchRecipes(int productId) async {
    _isLoadingRecipes = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/admin/recipes/$productId');
      final List<dynamic> list = response['recipe_items'];
      _currentRecipes = list.map((json) => Recipe.fromJson(json)).toList();
    } catch (e) {
      _currentRecipes = [];
    } finally {
      _isLoadingRecipes = false;
      notifyListeners();
    }
  }
  Future<void> addRecipeItem(int productId, int ingredientId, double qty) async {
    final body = {"product_id": productId, "ingredient_id": ingredientId, "quantity_needed": qty};
    await _apiService.post('/admin/recipes', body);
    await fetchRecipes(productId);
  }
  Future<void> deleteRecipeItem(int recipeId, int productId) async {
    await _apiService.delete('/admin/recipes/$recipeId');
    _currentRecipes.removeWhere((r) => r.recipeId == recipeId);
    notifyListeners();
  }

  // ==========================
  // INGREDIENT LOGIC (BAHAN BAKU)
  // ==========================

  // Fetch Semua Bahan
  Future<void> fetchIngredients() async {
    _isLoadingIngredients = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/admin/ingredients');
      final List<dynamic> list = response;
      _ingredients = list.map((json) => Ingredient.fromJson(json)).toList();
    } catch (e) {
      print("Error fetch ingredients: $e");
      rethrow;
    } finally {
      _isLoadingIngredients = false;
      notifyListeners();
    }
  }

  // Alias agar kompatibel dengan kode ProductManagementPage sebelumnya
  Future<void> fetchIngredientsList() async => fetchIngredients();
  List<Ingredient> get ingredientsList => _ingredients;

  // Tambah Bahan
  Future<void> addIngredient(Map<String, dynamic> body) async {
    await _apiService.post('/admin/ingredients', body);
    await fetchIngredients();
  }

  // Update Bahan
  Future<void> updateIngredient(int id, Map<String, dynamic> body) async {
    await _apiService.put('/admin/ingredients/$id', body);
    await fetchIngredients();
  }

  // Hapus Bahan
  Future<void> deleteIngredient(int id) async {
    await _apiService.delete('/admin/ingredients/$id');
    _ingredients.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  // --- STATE FINANCE ---
  ProfitLossModel? _profitLoss;
  double _totalAssetValue = 0;
  SalesReportModel? _salesReport;
  bool _isLoadingFinance = false;

  ProfitLossModel? get profitLoss => _profitLoss;
  double get totalAssetValue => _totalAssetValue;
  SalesReportModel? get salesReport => _salesReport;
  bool get isLoadingFinance => _isLoadingFinance;

  // --- 1. FETCH FINANCE DATA (Gabungan beberapa API) ---
  Future<void> fetchFinanceData({String? startDate, String? endDate}) async {
    _isLoadingFinance = true;
    notifyListeners();

    try {
      // Setup query params tanggal (jika ada)
      String query = "";
      if (startDate != null && endDate != null) {
        query = "?start_date=$startDate&end_date=$endDate";
      }

      // A. Fetch Laba Rugi
      final plResponse = await _apiService.get('/admin/reports/profit-loss$query');
      _profitLoss = ProfitLossModel.fromJson(plResponse);

      // B. Fetch Nilai Aset Gudang (Stok) - Tidak butuh filter tanggal
      final stockResponse = await _apiService.get('/admin/reports/stock');
      _totalAssetValue = (stockResponse['total_asset_value'] as num).toDouble();

      // C. Fetch Tren Penjualan (Untuk Grafik)
      final salesResponse = await _apiService.get('/admin/reports/sales$query');
      _salesReport = SalesReportModel.fromJson(salesResponse);

    } catch (e) {
      print("Error fetch finance: $e");
      _errorMessage = e.toString();
    } finally {
      _isLoadingFinance = false;
      notifyListeners();
    }
  }

  // --- 2. INPUT BIAYA OPERASIONAL ---
  Future<void> addExpense(String name, double amount, String date) async {
    try {
      await _apiService.post('/admin/expenses', {
        "name": name,
        "amount": amount,
        "date": date,
        "description": "Input via Mobile App"
      });
      // Refresh data keuangan setelah input biaya agar Laba Bersih update
      await fetchFinanceData(startDate: date, endDate: date); // Refresh sesuai konteks tanggal
    } catch (e) {
      rethrow;
    }
  }
}