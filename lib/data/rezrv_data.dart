import 'package:flutter/material.dart';

class RezrvData {
  // 🟢 We must declare the lists here so the app can store the data!
  static final ValueNotifier<List<Map<String, dynamic>>> upcomingReservations = ValueNotifier([]);
  static final ValueNotifier<List<Map<String, dynamic>>> historyReservations = ValueNotifier([]);

  static void addReservation({
    required String title,
    required String category,
    required String date,
    required String img,
    required String time,
    required String providerName,
    required String totalPrice,
    required String bookingId,
  }) {
    final newReservation = {
      "id": bookingId,
      "title": title,
      "category": category,
      "date": date,
      "time": time,
      "img": img,
      "providerName": providerName,
      "totalPrice": totalPrice,
      "status": "upcoming",
    };

    upcomingReservations.value = [...upcomingReservations.value, newReservation];
  }

  static void cancelReservation(String id) {
    final upcoming = List<Map<String, dynamic>>.from(upcomingReservations.value);
    final history = List<Map<String, dynamic>>.from(historyReservations.value);

    final index = upcoming.indexWhere((item) => item["id"] == id);
    if (index != -1) {
      final item = upcoming.removeAt(index);
      item["status"] = "cancelled";
      history.insert(0, item);

      upcomingReservations.value = upcoming;
      historyReservations.value = history;
    }
  }
}