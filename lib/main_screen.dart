import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'widgets/glass_nav_bar.dart';
import 'widgets/nav_item.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'views/home_view.dart';
import 'views/explore_view.dart';
import 'views/my_rezrv_view.dart';
import 'views/saved_view.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver { // 🟢 ADD "with WidgetsBindingObserver"
  int _selectedIndex = 0;

  // 🟢 ADD THIS: Setup encrypted storage
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final List<NavItem> _navItems = [
    NavItem(icon: HugeIcons.strokeRoundedGridView, title: 'Home'),
    NavItem(icon: HugeIcons.strokeRoundedLocation01, title: 'Explore'),
    NavItem(icon: HugeIcons.strokeRoundedTicket01, title: 'My Rezrv'),
    NavItem(icon: HugeIcons.strokeRoundedFavourite, title: 'Saved'),
  ];

  final List<Widget> _views = [
    const HomeView(),
    const ExploreView(),
    const MyRezrvView(),
    const SavedView(),
  ];

  @override
  void initState() {
    super.initState();
    // 🟢 ADD THIS: Start listening to app lifecycle (foreground/background)
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // 🟢 ADD THIS: Stop listening when the widget is destroyed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 🟢 Record the time when the user leaves the app (Background or Inactive)
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _secureStorage.write(
        key: 'last_exit_time',
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      debugPrint("App Backgrounded: Timestamp saved.");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detect keyboard
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      // Safely fetches the correct background color from the current theme (Light or Dark)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          IndexedStack(
              index: _selectedIndex,
              children: _views
          ),

          // Only render the Navbar if the keyboard is hidden
          if (!isKeyboardOpen)
            Positioned(
              left: 10,
              right: 10,
              bottom: 15,
              child: Center(
                child: GlassNavigationBar(
                  selectedIndex: _selectedIndex,
                  items: _navItems,
                  onItemSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}