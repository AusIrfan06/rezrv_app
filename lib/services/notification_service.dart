import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/notification_data.dart';
import '../main.dart';
import '../screens/booking_ticket_screen.dart';
import '../main_screen.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
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

          final ticketScreen = BookingTicketScreen(
            shopName: data['shopName'],
            category: data['category'],
            shopImage: data['shopImage'],
            providerName: data['providerName'],
            date: data['date'],
            time: data['time'],
            totalPrice: data['totalPrice'],
            bookingId: data['bookingId'],
          );

          // 🟢 Orchestrate the routing securely
          if (isAppCurrentlyLocked) {
            // App is locked! Just hand the ticket to main.dart and let the user unlock.
            pendingNotificationRoute = ticketScreen;
          } else {
            // App is already unlocked. Safely wipe and stack instantly.
            isBypassingLock = true;
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainScreen()),
                  (route) => false,
            );
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (_) => ticketScreen),
            ).then((_) {
              isBypassingLock = false;
            });
          }
        }
      },
    );

    await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

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

    // 🟢 Create a Group Key so Android and iOS stack them cleanly
    const String groupKey = 'com.rezrv.app.BOOKING_GROUP';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'booking_channel', 'Bookings',
      channelDescription: 'Notifications for confirmed bookings',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.blue,
      groupKey: groupKey, // Link them to the group
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      threadIdentifier: 'booking_group', // iOS grouping equivalent
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final String title = "Booking Confirmed! 🎉";
    final String message = "Your appointment at $shopName has been successfully reserved.";

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

    // 1. Show the individual notification with a UNIQUE ID so they don't overwrite each other
    int uniqueId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 🟢 FIXED: Using strict named arguments!
    await _notificationsPlugin.show(
      id: uniqueId,
      title: title,
      body: message,
      notificationDetails: platformDetails,
      payload: payloadData,
    );

    // 2. Show the invisible "Group Summary" to activate Android InboxStyle stacking
    const AndroidNotificationDetails summaryDetails = AndroidNotificationDetails(
      'booking_channel', 'Bookings',
      channelDescription: 'Notifications for confirmed bookings',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.blue,
      groupKey: groupKey,
      setAsGroupSummary: true, // This magically bundles them!
    );

    // 🟢 FIXED: Using strict named arguments!
    await _notificationsPlugin.show(
      id: 0, // ID 0 is strictly reserved for the parent bundle
      title: '',
      body: '',
      notificationDetails: const NotificationDetails(android: summaryDetails),
    );

    await NotificationData.addNotification(
        type: 'booking',
        title: title,
        message: message
    );
  }
}