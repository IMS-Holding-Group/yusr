import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiClient {
  static String get baseUrl => AppConfig.apiBaseUrl;
  
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالخادم: $e'};
    }
  }
  
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      Uri uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      
      final response = await http.get(uri);
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالخادم: $e'};
    }
  }
  
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    return await post('/auth/register', {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    });
  }
  
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    // Send identifier (can be email or phone)
    return await post('/auth/login', {
      'identifier': identifier,
      'password': password,
    });
  }
  
  Future<Map<String, dynamic>> getCategories() async {
    return await get('/categories');
  }
  
  Future<Map<String, dynamic>> searchProducts({
    String? query,
    int? categoryId,
    int page = 1,
  }) async {
    Map<String, String> params = {'page': page.toString()};
    if (query != null && query.isNotEmpty) {
      params['query'] = query;
    }
    if (categoryId != null) {
      params['category'] = categoryId.toString();
    }
    return await get('/products', queryParams: params);
  }
  
  Future<Map<String, dynamic>> getProduct(int productId) async {
    return await get('/products/$productId');
  }
  
  Future<Map<String, dynamic>> addToCart({
    required int userId,
    required int productId,
    int quantity = 1,
  }) async {
    return await post('/cart/add', {
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
    });
  }
  
  Future<Map<String, dynamic>> getCart(int userId) async {
    return await get('/cart', queryParams: {'user_id': userId.toString()});
  }
  
  Future<Map<String, dynamic>> checkout({
    required int userId,
    required String paymentMethod,
    required String address,
  }) async {
    return await post('/checkout', {
      'user_id': userId,
      'payment_method': paymentMethod,
      'address': address,
    });
  }
  
  Future<Map<String, dynamic>> getOrderStatus({
    required int orderId,
    required int userId,
  }) async {
    return await get('/order/$orderId/status', queryParams: {
      'user_id': userId.toString(),
    });
  }
  
  Future<Map<String, dynamic>> requestReturn({
    required int orderId,
    required int userId,
    String reason = '',
  }) async {
    return await post('/returns', {
      'order_id': orderId,
      'user_id': userId,
      'reason': reason,
    });
  }
  
  Future<Map<String, dynamic>> processNLU(String text) async {
    try {
      // التحقق من أن النص ليس فارغاً
      final cleanedText = text.trim();
      if (cleanedText.isEmpty) {
        return {
          'intent': 'unknown',
          'message': 'النص فارغ',
          'speak_text': 'لم يتم إرسال نص'
        };
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/nlu'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': cleanedText}),
      );
      
      if (response.statusCode == 400) {
        print('Backend returned 400 for text: $cleanedText');
        return {
          'intent': 'unknown',
          'message': 'خطأ في معالجة النص',
          'speak_text': 'لم أفهم الأمر، يرجى المحاولة مرة أخرى'
        };
      }
      
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      print('Error in processNLU: $e');
      return {
        'intent': 'error',
        'message': 'خطأ في الاتصال بالخادم: $e',
        'speak_text': 'حدث خطأ أثناء معالجة الطلب'
      };
    }
  }
  
  Future<Map<String, dynamic>> updateCartItem({
    required int userId,
    required int productId,
    required int quantity,
  }) async {
    return await post('/cart/update', {
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
    });
  }
  
  Future<Map<String, dynamic>> getUserOrders(int userId) async {
    return await get('/orders', queryParams: {
      'user_id': userId.toString(),
    });
  }
}

