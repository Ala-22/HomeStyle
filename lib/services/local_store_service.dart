import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';
import '../models/product_model.dart';
import 'database_service.dart';

class LocalStoreService {
  // =========================
  // FAVORITES (SQLite)
  // =========================

  Future<List<ProductModel>> getFavorites() =>
      DatabaseService.instance.getFavorites();

  Future<bool> isFavorite(int id) =>
      DatabaseService.instance.isFavorite(id);

  Future<bool> toggleFavorite(ProductModel product) =>
      DatabaseService.instance.toggleFavorite(product);

  // =========================
  // CART (SQLite)
  // =========================

  Future<List<CartItem>> getCart() => DatabaseService.instance.getCart();

  Future<int> cartCount() => DatabaseService.instance.cartCount();

  Future<bool> isInCart(int id) => DatabaseService.instance.isInCart(id);

  Future<void> addToCart(ProductModel product) =>
      DatabaseService.instance.addToCart(product);

  Future<void> updateQuantity(int id, int quantity) =>
      DatabaseService.instance.updateQuantity(id, quantity);

  Future<void> removeFromCart(int id) =>
      DatabaseService.instance.removeFromCart(id);

  Future<void> clearCart() => DatabaseService.instance.clearCart();

  // =========================
  // ORDERS
  // =========================

  static const String _ordersKey = 'orders_v1';

  Future<List<Map<String, dynamic>>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_ordersKey);

    if (raw == null) return [];

    try {
      final list = jsonDecode(raw) as List;

      return list
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addOrder({
    required double total,
    required int itemCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final orders = await getOrders();

    orders.insert(
      0,
      {
        'date': DateTime.now().toIso8601String(),
        'total': total,
        'itemCount': itemCount,
      },
    );

    await prefs.setString(_ordersKey, jsonEncode(orders));
  }

  Future<void> clearOrders() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_ordersKey, jsonEncode([]));
  }
}