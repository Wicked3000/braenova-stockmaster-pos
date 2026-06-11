import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:5000/api/v1'; // Emulator localhost
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

  // --- Dashboard ---
  Future<Response> getDashboardSummary() async {
    return await dio.get('/dashboard/summary');
  }

  // --- POS / Checkout ---
  Future<Response> checkout(Map<String, dynamic> checkoutData) async {
    return await dio.post('/checkout', data: checkoutData);
  }
}
