import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/product_model.dart';

class ApiService {
  static const String baseUrl =
      'http://localhost/homestyle_api';

  static const String aiBaseUrl = 'http://localhost:8000';

  // =========================
  // PRODUCTS
  // =========================

  Future<List<ProductModel>> getProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products.php'),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data
          .map((item) => ProductModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  // =========================
  // REGISTER
  // =========================

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register.php'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Registration failed');
    }
  }

  // =========================
  // LOGIN
  // =========================

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login.php'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login failed');
    }
  }

  // =========================
  // FORGOT PASSWORD
  // =========================

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot_password.php'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Password reset failed');
    }
  }

  // =========================
  // DELETE ACCOUNT
  // =========================

  Future<Map<String, dynamic>> deleteAccount({
    required int userId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/delete_account.php'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Delete account failed');
    }
  }

  // =========================
  // AI ROOM DESIGNER
  // =========================

  Future<Map<String, dynamic>> generateDesign({
    required String roomType,
    required String description,
    String? style,
  }) async {
    final response = await http.post(
      Uri.parse('$aiBaseUrl/generate'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'room': roomType,
        'description': description,
        if (style != null && style.isNotEmpty) 'style': style,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to generate design');
    }
  }

  // =========================
  // AI DESIGN -> SAVE TO AI IMAGES
  // =========================

  Future<Map<String, dynamic>> saveDesignToGallery({
    required String filename,
    required String name,
    double? price,
  }) async {
    final response = await http.post(
      Uri.parse('$aiBaseUrl/save-design'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'filename': filename,
        'name': name,
        'price': price,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return body;
    } else {
      throw Exception(
        body['message']?.toString() ?? 'Failed to save the design',
      );
    }
  }
}