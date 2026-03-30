import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/notification_data.dart'; // 🟢 THE MISSING IMPORT
import '../main.dart'; // To access navigatorKey and isBypassingLock
import '../screens/booking_ticket_screen.dart'; // To route directly to the ticket

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 🟢 Points directly to the file you pasted in the drawable folder!
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@drawable/ic_notification');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
        android: androidInit,
        macOS: iosInit,
        iOS: iosInit
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.startsWith('{')) {
          final data = jsonDecode(response.payload!);

          // Bypass app lock to show the ticket
          isBypassingLock = true;

          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => BookingTicketScreen(
                shopName: data['shopName'],
                category: data['category'],
                shopImage: data['shopImage'],
                providerName: data['providerName'],
                date: data['date'],
                time: data['time'],
                totalPrice: data['totalPrice'],
                bookingId: data['bookingId'],
              ),
            ),
          ).then((_) {
            // Re-enable app lock when leaving the ticket
            isBypassingLock = false;
          });
        }
      },
    );

    await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  // Call this right after the user clicks "Pay" or "Confirm"
  static Future<void> showBookingConfirmed({
    required String shopName,
    required String category,
    required String shopImage,
    required String providerName,
    required String date,
    required String time,
    required String totalPrice,
    required String bookingId,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'booking_channel', 'Bookings',
      channelDescription: 'Notifications for confirmed bookings',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.blue,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    final String title = "Booking Confirmed! 🎉";
    final String message = "Your appointment at $shopName has been successfully reserved.";

    // Pack the data into a hidden JSON string
    final payloadData = jsonEncode({
      'shopName': shopName,
      'category': category,
      'shopImage': shopImage,
      'providerName': providerName,
      'date': date,
      'time': time,
      'totalPrice': totalPrice,
      'bookingId': bookingId,
    });

    await _notificationsPlugin.show(
      id: 0,
      title: title,
      body: message,
      notificationDetails: platformDetails,
      payload: payloadData, // Attach the hidden data here
    );

    // Save it to our in-app Glassmorphic Screen
    await NotificationData.addNotification(
        type: 'booking',
        title: title,
        message: message
    );
  }
}