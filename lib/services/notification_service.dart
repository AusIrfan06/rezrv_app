import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/notification_data.dart';
import '../main.dart'; // To access the navigator key

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Android setup (looks for the default flutter icon)
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS setup
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

    // 🟢 FIXED: Uses the newest 'settings:' named parameter
    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload == 'open_bookings') {
          // 🟢 Navigates the user to the bookings tab when they tap the OS banner
          navigatorKey.currentState?.pushNamed('/bookings');
        }
      },
    );

    // Request permission for Android 13+ so the OS doesn't block the popup
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Call this right after the user clicks "Pay" or "Confirm"
  static Future<void> showBookingConfirmed(String shopName) async {
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

    // 🟢 FIXED: Uses strict named arguments for the newest package version
    await _notificationsPlugin.show(
      id: 0,
      title: title,
      body: message,
      notificationDetails: platformDetails,
      payload: 'open_bookings',
    );

    // Save it to our in-app Glassmorphic Screen
    await NotificationData.addNotification(
      type: 'booking',
      title: title,
      message: message,
    );
  }
}