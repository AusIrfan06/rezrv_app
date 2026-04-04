import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:rezrv/l10n/generated/app_localizations.dart';
import '../data/user_data.dart';
import 'state.dart';
import 'main_screen.dart';
import '../screens/app_lock_screen.dart';
import '../services/notification_service.dart';
import '../data/notification_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'package:google_fonts/google_fonts.dart';

// 🟢 GLOBAL VARIABLES FOR CLEAN ROUTING
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool isBypassingLock = false;

// 🟢 FIX 1: Start this as TRUE. This forces ANY startup notifications to "park" safely in the variable.
bool isAppCurrentlyLocked = true;
Widget? pendingNotificationRoute;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Initialize Supabase
    await Supabase.initialize(
      url: 'https://xcakmlfdwxdtfdvvvgso.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjYWttbGZkd3hkdGZkdnZ2Z3NvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4OTEyMjIsImV4cCI6MjA5MDQ2NzIyMn0.XXYmezxxuc7Y2uM75vPFQpj3bMeRDrNe1L9kXyNYq7w',
    );

    // 2. Test Connection
    final testData = await Supabase.instance.client.from('profiles').select().limit(1);
    debugPrint("✅ SUPABASE CONNECTION SUCCESSFUL! Data: $testData");

    // 3. Auto-Sync and Load Local Data
    await SupabaseService.syncUserOnStartup();
    await UserData.loadSavedData();
    await NotificationData.loadNotifications();
    await LocalNotificationService.initialize();

    // 4. Check for cold-start notifications
    await LocalNotificationService.checkInitialNotification();

  } catch (e) {
    debugPrint("❌ CRITICAL STARTUP ERROR CAUGHT: $e");
  }

  // 5. Run the app!
  runApp(const RezrvApp(startLocked: false));
}

class RezrvApp extends StatefulWidget {
  final bool startLocked;
  const RezrvApp({super.key, required this.startLocked});

  @override
  State<RezrvApp> createState() => _RezrvAppState();
}

class _RezrvAppState extends State<RezrvApp> with WidgetsBindingObserver {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  late bool _isLocked;

  @override
  void initState() {
    super.initState();
    _isLocked = widget.startLocked;

    // 🟢 FIX 2: Now that the app is building, we set the REAL lock status
    isAppCurrentlyLocked = widget.startLocked;

    WidgetsBinding.instance.addObserver(this);

    // 🟢 FIX 3: IF THE APP BOOTS UNLOCKED, SAFELY PUSH THE TICKET AFTER DRAWING THE SCREEN!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isLocked && pendingNotificationRoute != null) {
        // Grab it and clear it instantly
        final ticketScreenToPush = pendingNotificationRoute!;
        pendingNotificationRoute = null;

        // Wait a tiny fraction of a second for MainScreen to finish drawing, then push ticket!
        Future.delayed(const Duration(milliseconds: 200), () {
          navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (_) => ticketScreenToPush)
          );
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (isBypassingLock) return;
    if (state == AppLifecycleState.paused) {
      _lockApp();
    }
  }

  void _lockApp() {
    final bool isEnabled = UserData.appLockEnabled.value;
    final int timeout = UserData.appLockTimeout.value;

    if (isEnabled && timeout == 0 && !_isLocked) {
      isAppCurrentlyLocked = true;
      setState(() => _isLocked = true);

      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => AppLockScreen(
          onUnlocked: _handleUnlock,
        )),
            (route) => false,
      );
    }
  }

  // 🟢 CENTRALIZED ROUTING HUB (For when the app was locked)
  void _handleUnlock() {
    isAppCurrentlyLocked = false;
    setState(() => _isLocked = false);

    // 1. Always put MainScreen at the absolute bottom
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
    );

    // 2. If a notification was waiting for you, pop the ticket cleanly on top!
    if (pendingNotificationRoute != null) {
      final ticketScreenToPush = pendingNotificationRoute!;
      pendingNotificationRoute = null;

      Future.delayed(const Duration(milliseconds: 150), () {
        navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => ticketScreenToPush)
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeNotifier,
      builder: (context, currentTheme, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: appLocaleNotifier,
          builder: (context, currentLocale, _) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              title: 'Rezrv',
              themeMode: currentTheme,
              theme: ThemeData(
                brightness: Brightness.light,
                useMaterial3: true,
                scaffoldBackgroundColor: const Color(0xFFF8F9FA),
                fontFamily: 'Inter',
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                useMaterial3: true,
                scaffoldBackgroundColor: const Color(0xFF121212),
                fontFamily: 'Inter',
              ),
              locale: currentLocale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routes: {
                '/bookings': (context) => const MainScreen(),
              },
              home: widget.startLocked && _isLocked
                  ? AppLockScreen(onUnlocked: _handleUnlock)
                  : const MainScreen(),
            );
          },
        );
      },
    );
  }

  // 🟢 Add this to your SupabaseService
  static StreamSubscription<List<Map<String, dynamic>>>? _notificationSubscription;

  static void listenToNotifications() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Kills any old streams if the user logs out and logs back in
    _notificationSubscription?.cancel();

    // 🟢 The Magic Realtime Stream
    _notificationSubscription = Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
    // 🟢 1. Server-side filter: Only get THIS user's notifications
        .eq('recipient_id', userId)
        .listen((List<Map<String, dynamic>> allUserNotifications) {

      // 🟢 2. Local filter: Count only the ones where 'is_read' is false
      final unreadNotifications = allUserNotifications.where((notification) {
        return notification['is_read'] == false;
      }).toList();

      // 🟢 3. Update the UI
      NotificationData.unreadCount.value = unreadNotifications.length;

    });
  }
}