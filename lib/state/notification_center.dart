import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/app_notification.dart';

class NotificationCenter extends ChangeNotifier {
  static const _kKey = 'app.notifications';
  final _uuid = const Uuid();
  final List<AppNotification> _items = [];

  List<AppNotification> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((n) => !n.read).length;

  NotificationCenter() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _items.clear();
        for (final e in decoded) {
          try {
            _items.add(AppNotification.fromJson(Map<String, dynamic>.from(e as Map)));
          } catch (e) {
            debugPrint('NotificationCenter skip corrupt entry: $e');
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('NotificationCenter load error: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_items.map((e) => e.toJson()).toList());
      await prefs.setString(_kKey, raw);
    } catch (e) {
      debugPrint('NotificationCenter persist error: $e');
    }
  }

  Future<AppNotification> add({required String title, required String body}) async {
    final n = AppNotification(id: _uuid.v4(), title: title, body: body, createdAt: DateTime.now());
    _items.insert(0, n);
    notifyListeners();
    await _persist();
    return n;
  }

  Future<void> markRead(String id, bool read) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    _items[idx].read = read;
    notifyListeners();
    await _persist();
  }

  Future<void> markAllRead() async {
    for (final n in _items) {
      n.read = true;
    }
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    await _persist();
  }
}
