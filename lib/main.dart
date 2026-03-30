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

// 🟢 GLOBAL VARIABLES FOR CLEAN ROUTING
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool isBypassingLock = false;
bool isAppCurrentlyLocked = false;
Widget? pendingNotificationRoute;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserData.loadSavedData();
  await NotificationData.loadNotifications();
  await LocalNotificationService.initialize();
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
    isAppCurrentlyLocked = widget.startLocked;
    WidgetsBinding.instance.addObserver(this);
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
          onUnlocked: _handleUnlock, // 🟢 Route cleanly using the new function below
        )),
            (route) => false,
      );
    }
  }

  // 🟢 CENTRALIZED ROUTING HUB
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
      navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => pendingNotificationRoute!)
      );
      pendingNotificationRoute = null; // Clear it out
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
                  ? AppLockScreen(onUnlocked: _handleUnlock) // 🟢 Use the hub here too
                  : const MainScreen(),
            );
          },
        );
      },
    );
  }
}