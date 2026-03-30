import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationData {
  // Global listener for the UI
  static ValueNotifier<List<Map<String, dynamic>>> notifications = ValueNotifier([]);

  // Load from disk when app starts
  static Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString('saved_notifications');
    if (saved != null) {
      List<dynamic> decoded = json.decode(saved);
      notifications.value = decoded.cast<Map<String, dynamic>>();
    }
  }

  // Save to disk
  static Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_notifications', json.encode(notifications.value));
  }

  // Add a new notification
  static Future<void> addNotification({required String type, required String title, required String message}) async {
    final newNotif = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "type": type,
      "title": title,
      "message": message,
      "time": "Just now",
      "isUnread": true,
    };

    // Insert at the top of the list
    notifications.value = [newNotif, ...notifications.value];
    await _saveToDisk();
  }

  static Future<void> markAllAsRead() async {
    final updatedList = notifications.value.map((n) {
      n["isUnread"] = false;
      return n;
    }).toList();
    notifications.value = updatedList;
    await _saveToDisk();
  }

  static Future<void> removeNotification(String id) async {
    final updatedList = List<Map<String, dynamic>>.from(notifications.value);
    updatedList.removeWhere((n) => n["id"] == id);
    notifications.value = updatedList;
    await _saveToDisk();
  }
}