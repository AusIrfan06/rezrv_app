import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/notification_data.dart';
import '../main.dart';
import '../screens/booking_ticket_screen.dart';
import '../main_screen.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // 🟢 2. INITIALIZE STORAGE FOR OUR HOT RESTART SHIELD
  static const _storage = FlutterSecureStorage();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('ic_notification');

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
          _handleNotificationPayload(response.payload!);
        }
      },
    );

    await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  static Future<void> checkInitialNotification() async {
    final NotificationAppLaunchDetails? launchDetails = await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      final response = launchDetails.notificationResponse;
      if (response != null && response.payload != null && response.payload!.startsWith('{')) {
        _handleNotificationPayload(response.payload!);
      }
    }
  }

  // 🟢 3. CONVERTED TO ASYNC & ADDED THE GHOST INTENT BLOCKER
  static Future<void> _handleNotificationPayload(String payload) async {

    // 🛡️ THE HOT RESTART SHIELD
    // Check if we already processed this exact notification before the app restarted
    final lastPayload = await _storage.read(key: 'last_processed_notification');

    if (lastPayload == payload) {
      debugPrint("👻 GHOST INTENT BLOCKED! Ignoring cached Hot Restart notification.");
      return; // Stop right here! Don't push the ticket screen!
    }

    // If it is a brand new booking, save it so we remember it next time!
    await _storage.write(key: 'last_processed_notification', value: payload);

    // Continue with normal routing...
    final data = jsonDecode(payload);

    final ticketScreen = BookingTicketScreen(
      shopId: '',
      shopName: data['shopName'],
      category: data['category'],
      shopImage: data['shopImage'],
      providerName: data['providerName'],
      date: data['date'],
      time: data['time'],
      totalPrice: data['totalPrice'],
      bookingId: data['bookingId'],
    );

    if (isAppCurrentlyLocked) {
      pendingNotificationRoute = ticketScreen;
    } else {
      isBypassingLock = true;
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
      );

      Future.delayed(const Duration(milliseconds: 150), () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => ticketScreen),
        ).then((_) {
          isBypassingLock = false;
        });
      });
    }
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

    const String groupKey = 'com.rezrv.app.BOOKING_GROUP';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'booking_channel_v3',
      'Bookings',
      channelDescription: 'Notifications for confirmed bookings',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.blue,
      groupKey: groupKey,
      icon: 'ic_notification',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      threadIdentifier: 'booking_group',
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
      'bookingId': bookingId, // This unique ID guarantees our Shield works perfectly!
    });

    int uniqueId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notificationsPlugin.show(
      id: uniqueId,
      title: title,
      body: message,
      notificationDetails: platformDetails,
      payload: payloadData,
    );

    const AndroidNotificationDetails summaryDetails = AndroidNotificationDetails(
      'booking_channel_v3',
      'Bookings',
      channelDescription: 'Notifications for confirmed bookings',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.blue,
      groupKey: groupKey,
      setAsGroupSummary: true,
      icon: 'ic_notification',
    );

    await _notificationsPlugin.show(
      id: 0,
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