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

// 🟢 1. Create a Global Key to control navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool isBypassingLock = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🟢 Add this line to load your saved profile data
  await UserData.loadSavedData();

  runApp(const RezrvApp(startLocked: false)); // or your app entry
}

// 🟢 2. Convert to StatefulWidget to use Lifecycle Observer
class RezrvApp extends StatefulWidget {
  final bool startLocked; // 🟢 Accept the pre-fetched status
  const RezrvApp({super.key, required this.startLocked});

  @override
  State<RezrvApp> createState() => _RezrvAppState();
}

class _RezrvAppState extends State<RezrvApp> with WidgetsBindingObserver {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  late bool _isLocked; // 🟢 Changed to 'late'

  @override
  void initState() {
    super.initState();
    _isLocked = widget.startLocked; // 🟢 Initialize instantly from pre-fetch
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

    // 🟢 Lock the app when it is hidden (paused)
    if (state == AppLifecycleState.paused) {
      _lockApp();
    }
  }

  void _lockApp() {
    // 🟢 Use global variables instead of re-reading disk
    final bool isEnabled = UserData.appLockEnabled.value;
    final int timeout = UserData.appLockTimeout.value;

    // Only trigger if enabled and timeout is set to "Immediately" (0)
    if (isEnabled && timeout == 0 && !_isLocked) {
      debugPrint("🔒 App Locked via Lifecycle Notifier");

      setState(() => _isLocked = true);

      // Reset navigation to the lock screen
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => AppLockScreen(
          onUnlocked: () => setState(() => _isLocked = false),
        )),
            (route) => false,
      );
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

              // 🟢 THEME RESTORED!
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

              // 🟢 INSTANT ROUTING: No loading screens
              // 🟢 This checks the initial state from main()
              home: widget.startLocked && _isLocked
                  ? AppLockScreen(onUnlocked: () {
                setState(() => _isLocked = false);
              })
                  : const MainScreen(),
            );
          },
        );
      },
    );
  }
}