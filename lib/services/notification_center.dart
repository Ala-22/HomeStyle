import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String icon;
  final int colorIndex;
  final DateTime createdAt;

  bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    this.colorIndex = 0,
    DateTime? createdAt,
    this.read = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'icon': icon,
      'colorIndex': colorIndex,
      'createdAt': createdAt.toIso8601String(),
      'read': read,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      icon: json['icon'] ?? 'notifications',
      colorIndex: (json['colorIndex'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      read: json['read'] == true,
    );
  }
}

class NotificationCenter extends ChangeNotifier {
  NotificationCenter._();

  static final NotificationCenter instance = NotificationCenter._();

  static const String _key = 'notifications_v1';

  List<AppNotification> _items = [];

  List<AppNotification> get items => List.unmodifiable(_items);

  int get unreadCount =>
      _items.where((n) => !n.read).length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_key);

    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _items = list
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _items = [];
      }
    }

    if (_items.isEmpty) {
      _seed();
      await _save(prefs);
    }

    notifyListeners();
  }

  void _seed() {
    _items = [
      AppNotification(
        id: 'seed-welcome',
        title: 'Welcome to HomeStyle',
        body: 'Enjoy exploring beautiful ideas and products for your home.',
        icon: 'celebration',
        colorIndex: 3,
      ),
      AppNotification(
        id: 'seed-ai',
        title: '✨ AI Room Designer is live',
        body: 'Describe your dream room and let our AI design it for you.',
        icon: 'auto_awesome',
        colorIndex: 0,
      ),
      AppNotification(
        id: 'seed-offer',
        title: 'Exclusive 20% OFF',
        body: 'Special offers are available on selected products today only.',
        icon: 'local_offer',
        colorIndex: 2,
      ),
    ];
  }

  Future<void> push({
    required String title,
    required String body,
    String icon = 'notifications',
    int colorIndex = 0,
  }) async {
    _items.insert(
      0,
      AppNotification(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        body: body,
        icon: icon,
        colorIndex: colorIndex,
      ),
    );

    notifyListeners();
    await _save();
  }

  Future<void> markRead(String id) async {
    final idx = _items.indexWhere((n) => n.id == id);

    if (idx == -1) return;

    _items[idx].read = true;
    notifyListeners();
    await _save();
  }

  Future<void> markAllRead() async {
    for (final n in _items) {
      n.read = true;
    }

    notifyListeners();
    await _save();
  }

  Future<void> _save([SharedPreferences? prefs]) async {
    final prefsInstance = prefs ?? await SharedPreferences.getInstance();

    await prefsInstance.setString(
      _key,
      jsonEncode(_items.map((n) => n.toJson()).toList()),
    );
  }
}