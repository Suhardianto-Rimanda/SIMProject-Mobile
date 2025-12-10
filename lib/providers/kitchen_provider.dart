import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/kitchen_model.dart';
import '../models/ingredient_model.dart';

class KitchenProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // --- STATE STOK ---
  List<KitchenStockItem> _stocks = [];
  bool _isLoadingStocks = false;
  List<KitchenStockItem> get stocks => _stocks;
  bool get isLoadingStocks => _isLoadingStocks;

  // --- STATE ANTRIAN ---
  List<KitchenTaskGroup> _tasks = [];
  bool _isLoadingQueue = false;
  List<KitchenTaskGroup> get tasks => _tasks;
  bool get isLoadingQueue => _isLoadingQueue;

  // --- STATE DROPDOWN BAHAN ---
  List<Ingredient> _ingredientsList = [];
  List<Ingredient> get ingredientsList => _ingredientsList;

  // 1. Fetch Stok Gudang (Updated dengan Search)
  Future<void> fetchStocks({String query = ''}) async {
    _isLoadingStocks = true;
    notifyListeners();
    try {
      // Backend sudah support ?q=...
      final url = query.isEmpty ? '/production/stocks' : '/production/stocks?q=$query';
      final response = await _apiService.get(url);
      final List<dynamic> data = response['data'];
      _stocks = data.map((json) => KitchenStockItem.fromJson(json)).toList();
    } catch (e) {
      print("Error fetch stocks: $e");
    } finally {
      _isLoadingStocks = false;
      notifyListeners();
    }
  }

  // 2. Fetch Antrian Masak
  Future<void> fetchQueue() async {
    _isLoadingQueue = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/production/queue');
      final Map<String, dynamic> tasksMap = response['tasks'];

      List<KitchenTaskGroup> groups = [];
      tasksMap.forEach((menuName, data) {
        final List<dynamic> ordersJson = data['orders'];
        groups.add(KitchenTaskGroup(
          menuName: menuName,
          totalQty: data['total_qty'],
          orders: ordersJson.map((o) => KitchenQueueItem.fromJson(o)).toList(),
        ));
      });

      _tasks = groups;
    } catch (e) {
      print("Error fetch queue: $e");
    } finally {
      _isLoadingQueue = false;
      notifyListeners();
    }
  }

  // 3. Update Status Masakan
  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    try {
      await _apiService.put('/production/orders/$orderId/status', {
        'status': newStatus
      });
      await fetchQueue();
    } catch (e) {
      rethrow;
    }
  }

  // 4. Restock Bahan (Beli)
  Future<void> restockIngredient(int id, double qty, double price) async {
    try {
      await _apiService.post('/production/restock', {
        'ingredient_id': id,
        'qty': qty,
        'price': price
      });
      await fetchStocks();
    } catch (e) {
      rethrow;
    }
  }

  // 5. Stock Opname (Penyesuaian Manual)
  Future<void> adjustStock(int id, double qtyChange, String reason) async {
    try {
      await _apiService.post('/production/adjustment', {
        'ingredient_id': id,
        'qty_change': qtyChange,
        'reason': reason
      });
      await fetchStocks();
    } catch (e) {
      rethrow;
    }
  }

  // Helper: Ambil list nama bahan
  Future<void> fetchIngredientsList() async {
    try {
      final response = await _apiService.get('/production/ingredients');
      final List<dynamic> list = response['list'];
      _ingredientsList = list.map((json) => Ingredient.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      print("Error fetch ingredients: $e");
    }
  }
}