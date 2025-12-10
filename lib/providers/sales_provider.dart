import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';

class SalesProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // ... (State & Getter Lama TETAP ADA) ...
  bool _isLoading = false;
  bool _isShiftOpen = false;
  int? _activeSessionId;
  String? _errorMessage;
  List<Product> _menuList = [];
  final List<CartItem> _cart = [];
  List<OrderModel> _orderHistory = [];
  bool _isLoadingHistory = false;

  Map<String, dynamic>? _shiftReport;
  bool _isLoadingReport = false;

  // Getters...
  bool get isLoading => _isLoading;
  bool get isShiftOpen => _isShiftOpen;
  List<Product> get menuList => _menuList;
  List<CartItem> get cart => _cart;
  List<OrderModel> get orderHistory => _orderHistory;
  bool get isLoadingHistory => _isLoadingHistory;
  Map<String, dynamic>? get shiftReport => _shiftReport;
  bool get isLoadingReport => _isLoadingReport;

  double get totalTransactionAmount => _cart.fold(0, (sum, item) => sum + item.totalPrice);
  int get totalItems => _cart.fold(0, (sum, item) => sum + item.quantity);

  // ... (Fetch Menu, Add/Remove Cart TETAP ADA) ...
  Future<void> fetchMenu() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/sales/menu');
      final List<dynamic> data = response['menu'];
      _menuList = data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print("Error fetch menu: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addToCart(Product product) {
    final index = _cart.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _cart[index].quantity++;
    } else {
      _cart.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void decreaseQty(Product product) {
    final index = _cart.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      if (_cart[index].quantity > 1) {
        _cart[index].quantity--;
      } else {
        _cart.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // --- UPDATE: MENGEMBALIKAN STRING INVOICE ---
  Future<String> processTransaction({
    required String customerName,
    required String paymentMethod,
  }) async {
    if (_cart.isEmpty) throw Exception("Keranjang kosong");

    _isLoading = true;
    notifyListeners();

    try {
      final itemsPayload = _cart.map((item) => {
        "product_id": item.product.id,
        "qty": item.quantity
      }).toList();

      final body = {
        "customer_name": customerName,
        "payment_method": paymentMethod,
        "items": itemsPayload
      };

      // Ambil response dari backend
      final response = await _apiService.post('/sales/orders', body);

      // Kosongkan keranjang setelah sukses
      clearCart();
      fetchOrderHistory(); // Refresh history

      // Kembalikan nomor invoice (misal: "INV-2025...")
      return response['invoice'] ?? '-';

    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ... (Fungsi History, Payment, Shift, Report TETAP ADA SAMA SEPERTI SEBELUMNYA) ...
  Future<void> fetchOrderHistory() async {
    _isLoadingHistory = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/sales/orders/history');
      final List<dynamic> data = response;
      List<OrderModel> fetchedOrders = data.map((json) => OrderModel.fromJson(json)).toList();
      fetchedOrders.sort((a, b) {
        if (a.isUnpaid && !b.isUnpaid) return -1;
        if (!a.isUnpaid && b.isUnpaid) return 1;
        return b.transactionDate.compareTo(a.transactionDate);
      });
      _orderHistory = fetchedOrders;
    } catch (e) {
      print("Error fetch history: $e");
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> payPendingOrder(String invoiceNo, String method) async {
    try {
      await _apiService.post('/sales/orders/$invoiceNo/pay', {'payment_method': method});
      await fetchOrderHistory();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> checkShiftStatus() async {
    try {
      final response = await _apiService.get('/sales/dashboard');
      if (response['status'] == 'Shift Aktif') {
        _isShiftOpen = true;
        _activeSessionId = response['session_info']?['id'];
      } else {
        _isShiftOpen = false;
        _activeSessionId = null;
      }
      notifyListeners();
    } catch (e) {
      print("Error check shift: $e");
    }
  }

  Future<void> openShift(double startCash) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post('/sales/shift/open', {'start_cash': startCash});
      _isShiftOpen = true;
      _activeSessionId = response['session_id'];
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchShiftReport() async {
    _isLoadingReport = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/sales/dashboard');
      if (response['session_info'] != null) {
        _shiftReport = {
          'start_cash': response['session_info']['start_cash'],
          'total_sales': response['session_info']['total_sales'],
          'status': response['status'],
          'session_id': response['session_info']['id'],
        };
      } else {
        _shiftReport = null;
      }
    } catch (e) {
      print("Error fetch report: $e");
    } finally {
      _isLoadingReport = false;
      notifyListeners();
    }
  }

  Future<void> closeShift(double actualCash) async {
    try {
      await _apiService.post('/sales/shift/close', {'end_cash_actual': actualCash});
      _isShiftOpen = false;
      _activeSessionId = null;
      _shiftReport = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}