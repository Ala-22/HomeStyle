import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/cart_item.dart';
import '../models/product_model.dart';
import 'database_factory_stub.dart'
    if (dart.library.io) 'database_factory_io.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const String _dbName = 'homestyle.db';
  static const String _favoritesKey = 'favorites_v1';
  static const String _cartKey = 'cart_v1';

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;

    _db = await appDatabaseFactory.openDatabase(
      p.join(
        await appDatabaseFactory.getDatabasesPath(),
        _dbName,
      ),
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE favorites (
              id INTEGER PRIMARY KEY,
              name TEXT NOT NULL,
              description TEXT,
              price REAL NOT NULL,
              image TEXT,
              category TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE cart (
              id INTEGER PRIMARY KEY,
              name TEXT NOT NULL,
              description TEXT,
              price REAL NOT NULL,
              image TEXT,
              category TEXT,
              quantity INTEGER NOT NULL DEFAULT 1
            )
          ''');
        },
      ),
    );

    return _db!;
  }

  // =========================
  // FAVORITES
  // =========================

  Future<List<ProductModel>> getFavorites() async {
    if (kIsWeb) return _webGetFavorites();

    final db = await _database;
    final rows = await db.query('favorites');

    return rows.map(_productFromRow).toList();
  }

  Future<bool> isFavorite(int id) async {
    if (kIsWeb) return _webIsFavorite(id);

    final db = await _database;
    final rows = await db.query(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  Future<bool> toggleFavorite(ProductModel product) async {
    if (kIsWeb) return _webToggleFavorite(product);

    final db = await _database;
    final rows = await db.query(
      'favorites',
      where: 'id = ?',
      whereArgs: [product.id],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      await db.delete(
        'favorites',
        where: 'id = ?',
        whereArgs: [product.id],
      );
      return false;
    }

    await db.insert('favorites', _productToRow(product));
    return true;
  }

  // =========================
  // CART
  // =========================

  Future<List<CartItem>> getCart() async {
    if (kIsWeb) return _webGetCart();

    final db = await _database;
    final rows = await db.query('cart');

    return rows
        .map(
          (row) => CartItem(
            product: _productFromRow(row),
            quantity: row['quantity'] as int,
          ),
        )
        .toList();
  }

  Future<int> cartCount() async {
    final cart = await getCart();

    return cart.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  Future<bool> isInCart(int id) async {
    if (kIsWeb) return _webIsInCart(id);

    final db = await _database;
    final rows = await db.query(
      'cart',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  Future<void> addToCart(ProductModel product) async {
    if (kIsWeb) return _webAddToCart(product);

    final db = await _database;
    final rows = await db.query(
      'cart',
      where: 'id = ?',
      whereArgs: [product.id],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      await db.rawUpdate(
        'UPDATE cart SET quantity = quantity + 1 WHERE id = ?',
        [product.id],
      );
      return;
    }

    await db.insert(
      'cart',
      {..._productToRow(product), 'quantity': 1},
    );
  }

  Future<void> updateQuantity(int id, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(id);
      return;
    }

    if (kIsWeb) return _webUpdateQuantity(id, quantity);

    final db = await _database;
    await db.update(
      'cart',
      {'quantity': quantity},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> removeFromCart(int id) async {
    if (kIsWeb) return _webRemoveFromCart(id);

    final db = await _database;
    await db.delete('cart', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearCart() async {
    if (kIsWeb) return _webClearCart();

    final db = await _database;
    await db.delete('cart');
  }

  // =========================
  // HELPERS
  // =========================

  Map<String, dynamic> _productToRow(ProductModel p) => {
        'id': p.id,
        'name': p.name,
        'description': p.description,
        'price': p.price,
        'image': p.image,
        'category': p.category,
      };

  ProductModel _productFromRow(Map<String, dynamic> row) => ProductModel(
        id: row['id'] as int,
        name: row['name'] as String,
        description: row['description'] as String? ?? '',
        price: (row['price'] as num).toDouble(),
        image: row['image'] as String? ?? '',
        category: row['category'] as String? ?? '',
      );

  // =========================
  // WEB FALLBACK (SharedPreferences)
  // =========================

  Future<List<ProductModel>> _webGetFavorites() async {
    final raw =
        (await SharedPreferences.getInstance()).getString(_favoritesKey);
    if (raw == null) return [];

    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((item) =>
              ProductModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> _webIsFavorite(int id) async {
    final favorites = await _webGetFavorites();
    return favorites.any((p) => p.id == id);
  }

  Future<bool> _webToggleFavorite(ProductModel product) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await _webGetFavorites();

    if (favorites.any((p) => p.id == product.id)) {
      favorites.removeWhere((p) => p.id == product.id);
      await prefs.setString(_favoritesKey, jsonEncode(favorites));
      return false;
    }

    favorites.add(product);
    await prefs.setString(_favoritesKey, jsonEncode(favorites));
    return true;
  }

  Future<List<CartItem>> _webGetCart() async {
    final raw =
        (await SharedPreferences.getInstance()).getString(_cartKey);
    if (raw == null) return [];

    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        return CartItem(
          product: ProductModel.fromJson(
            map['product'] as Map<String, dynamic>,
          ),
          quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> _webIsInCart(int id) async {
    final cart = await _webGetCart();
    return cart.any((item) => item.product.id == id);
  }

  Future<void> _webAddToCart(ProductModel product) async {
    final prefs = await SharedPreferences.getInstance();
    final cart = await _webGetCart();

    final existing =
        cart.indexWhere((item) => item.product.id == product.id);

    if (existing >= 0) {
      cart[existing].quantity += 1;
    } else {
      cart.add(CartItem(product: product));
    }

    await _webPersistCart(prefs, cart);
  }

  Future<void> _webUpdateQuantity(int id, int quantity) async {
    final prefs = await SharedPreferences.getInstance();
    final cart = await _webGetCart();
    final existing = cart.indexWhere((item) => item.product.id == id);

    if (existing < 0) return;

    if (quantity <= 0) {
      cart.removeAt(existing);
    } else {
      cart[existing].quantity = quantity;
    }

    await _webPersistCart(prefs, cart);
  }

  Future<void> _webRemoveFromCart(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final cart = (await _webGetCart())
      ..removeWhere((item) => item.product.id == id);
    await _webPersistCart(prefs, cart);
  }

  Future<void> _webClearCart() async {
    await (await SharedPreferences.getInstance())
        .setString(_cartKey, jsonEncode([]));
  }

  Future<void> _webPersistCart(
    SharedPreferences prefs,
    List<CartItem> cart,
  ) async {
    final encoded = cart
        .map(
          (item) => {
            'product': item.product.toJson(),
            'quantity': item.quantity,
          },
        )
        .toList();

    await prefs.setString(_cartKey, jsonEncode(encoded));
  }
}