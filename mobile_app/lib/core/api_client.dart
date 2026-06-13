import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // Connected directly to the live Render Backend!
  static const String baseUrl = 'https://braenova-stockmaster-pos.onrender.com/api/v1';

  final Dio dio;
  final FlutterSecureStorage secureStorage;

  ApiClient()
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        )),
        secureStorage = const FlutterSecureStorage() {
    _setupInterceptors();
  }

  void _setupInterceptors() {

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await secureStorage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (options.data is! FormData) {
          options.headers['Content-Type'] = 'application/json';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        return handler.next(e);
      },
    ));
  }

  // --- Authentication ---
  
  Future<Response> register(Map<String, dynamic> data) async {
    return await dio.post('/auth/register', data: data);
  }
  Future<Response> login(String username, String password) async {
    final response = await dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
    // Save user info for profile display and role-based access
    if (response.data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      if (response.data['user'] != null) {
        await prefs.setString('role', response.data['user']['role'] ?? 'cashier');
        await prefs.setString('plan', response.data['user']['plan'] ?? 'starter');
      }
    }
    return response;
  }

  // --- Inventory ---
  Future<Response> getInventory() async {
    return await dio.get('/inventory');
  }

  Future<Response> getCategories() async {
    return await dio.get('/categories');
  }

  Future<Response> addProduct(Map<String, dynamic> productData) async {
    return await dio.post('/inventory', data: productData);
  }

  Future<Response> updateProduct(int id, Map<String, dynamic> productData) async {
    return await dio.put('/inventory/$id', data: productData);
  }

  Future<Response> deleteProduct(int id) async {
    return await dio.delete('/inventory/$id');
  }

  Future<Response> addCategory(String name) async {
    return await dio.post('/categories', data: {'name': name});
  }

  // --- Dashboard ---
  Future<Response> getDashboardSummary() async {
    return await dio.get('/dashboard/summary');
  }

  // --- Sales History ---
  Future<Response> getSalesHistory() async {
    return await dio.get('/sales');
  }

  // --- Cashiers / Staff Management ---
  Future<Response> getCashiers() async {
    return await dio.get('/cashiers');
  }

  Future<Response> addCashier(String username, String password) async {
    return await dio.post('/cashiers', data: {
      'username': username,
      'password': password,
    });
  }

  
  Future<Response> resetCashierPassword(int cashierId, String newPassword) async {
    return await dio.put('/cashiers/$cashierId/reset', data: {'password': newPassword});
  }
  Future<Response> deleteCashier(int cashierId) async {
    return await dio.delete('/cashiers/$cashierId');
  }

  // --- POS / Checkout ---
  Future<Response> checkout(Map<String, dynamic> checkoutData) async {
    return await dio.post('/checkout', data: checkoutData);
  }

  // --- Dinau (Store Credit) ---
  Future<Response> getDinauRecords() async {
    return await dio.get('/dinau');
  }

  Future<Response> addDinauRecord(Map<String, dynamic> data) async {
    return await dio.post('/dinau', data: data);
  }

  Future<Response> markDinauPaid(int recordId) async {
    return await dio.put('/dinau/$recordId', data: {'status': 'paid'});
  }

  Future<Response> deleteDinauRecord(int recordId) async {
    return await dio.delete('/dinau/$recordId');
  }
  // --- Warehouse ---
  Future<Response> getWarehouse() async {
    return await dio.get('/warehouse');
  }

  Future<Response> addWarehouseItem(Map<String, dynamic> data) async {
    return await dio.post('/warehouse', data: data);
  }

  Future<Response> updateWarehouseItem(int id, Map<String, dynamic> data) async {
    return await dio.put('/warehouse/$id', data: data);
  }

  Future<Response> deleteWarehouseItem(int id) async {
    return await dio.delete('/warehouse/$id');
  }

  // --- Expenses & Reports ---
  Future<Response> getExpenses() async {
    return await dio.get('/expenses');
  }

  Future<Response> addExpense(Map<String, dynamic> data) async {
    return await dio.post('/expenses', data: data);
  }

  Future<Response> getReports() async {
    return await dio.get('/reports');
  }

  // --- Upload Image ---
  Future<Response> uploadImage(List<int> bytes, String filename) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    return await dio.post('/upload', data: formData);
  }

  // --- Feature Parity Endpoints ---
  
  // Shifts
  Future<Response> getCurrentShift() async {
    return await dio.get('/shifts/current');
  }

  Future<Response> openShift(double startingFloat) async {
    return await dio.post('/shifts/open', data: {'starting_float': startingFloat});
  }

  Future<Response> closeShift(int shiftId, double actualCash) async {
    return await dio.post('/shifts/close', data: {'shift_id': shiftId, 'actual_cash': actualCash});
  }

  // Warehouse Operations
  Future<Response> restockWarehouse(int itemId, int quantity) async {
    return await dio.post('/warehouse/restock', data: {'item_id': itemId, 'quantity': quantity});
  }

  Future<Response> transferWarehouse(int itemId, int quantity) async {
    return await dio.post('/warehouse/transfer', data: {'item_id': itemId, 'quantity': quantity});
  }

  // End of Day
  Future<Response> closeDayReport() async {
    return await dio.post('/reports/close');
  }

  // Shop Profile
  Future<Response> updateShopProfile(Map<String, dynamic> data) async {
    return await dio.put('/shop/profile', data: data);
  }

  // Category Deletion
  Future<Response> deleteCategory(int catId) async {
    return await dio.delete('/category/delete/$catId');
  }
}
