import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  // Connected directly to the live Render Backend!
  static const String baseUrl = 'https://braenova-stockmaster-pos.onrender.com/api/v1'; 
  
  final Dio dio;
  final FlutterSecureStorage secureStorage;

  ApiClient()
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )),
        secureStorage = const FlutterSecureStorage() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Inject JWT token into headers if available
        final token = await secureStorage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Handle 401 Unauthorized globally (e.g., token expired)
        if (e.response?.statusCode == 401) {
          // Trigger logout or token refresh logic here
        }
        return handler.next(e);
      },
    ));
  }

  // --- Authentication ---
  Future<Response> login(String username, String password) async {
    return await dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
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

  Future<Response> deleteCashier(int cashierId) async {
    return await dio.delete('/cashiers/$cashierId');
  }

  // --- POS / Checkout ---
  Future<Response> checkout(Map<String, dynamic> checkoutData) async {
    return await dio.post('/checkout', data: checkoutData);
  }
}
