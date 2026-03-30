import 'dart:io';
import 'dart:ui'; // 🟢 Required for ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart'; // 🟢 For DeviceInfoPlugin
import 'package:device_marketing_names/device_marketing_names.dart'; // 🟢 For DeviceMarketingNames
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import '../data/user_data.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🟢 ADD THIS
import 'package:permission_handler/permission_handler.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final DeviceMarketingNames _marketingNames = DeviceMarketingNames();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // 🟢 REMOVED local booleans to prevent state-flicker
  bool _isTimeoutExpanded = false;
  String _cacheSize = "Calculating...";
  String _deviceName = "Detecting...";
  String _currentCountry = "Detecting...";
  String _currentCity = "";
  
  @override
  void initState() {
    super.initState();
    // 🟢 No longer loading settings here because main.dart did it.
    _calculateCacheSize();
    _loadDeviceFromCache();
  }

  // 3. 🟢 Instant load from storage
  Future<void> _loadDeviceFromCache() async {
    String? cachedName = await _secureStorage.read(key: 'cached_device_name');
    String? cachedCountry = await _secureStorage.read(key: 'cached_country');

    if (cachedName != null && mounted) {
      setState(() {
        _deviceName = cachedName;
        _currentCountry = cachedCountry ?? "Detecting...";
      });
    }
    // Still fetch in background to ensure it's up to date
    _getDeviceInfo();
  }

  Future<void> _getDeviceInfo() async {
    try {
      // 1. 🟢 THE SMART WAY: Use the built-in async method
      // This handles the DeviceInfoPlugin logic internally for you!
      String marketingName = await _marketingNames.getSingleName();

      // 2. 🟢 THE FALLBACK: If marketing name fails (or on Emulator),
      // get the basic info from DeviceInfoPlus.
      if (marketingName == "Unknown" || marketingName.isEmpty) {
        final deviceInfo = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          marketingName = "${androidInfo.brand} ${androidInfo.model}";
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          marketingName = iosInfo.name; // User's custom name like "Daus's iPhone"
        }
      }

      // 3. 🟢 THE LOCATION: Fetch the real City/Country
      final response = await http.get(Uri.parse('http://ip-api.com/json')).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _deviceName = marketingName;
            _currentCity = data['city'] ?? "Unknown City";
            _currentCountry = data['country'] ?? "Unknown Country";
          });

          // Save to cache for instant loading next time
          await _secureStorage.write(key: 'cached_device_name', value: marketingName);
          await _secureStorage.write(key: 'cached_country', value: "${data['city']}, ${data['country']}");
        }
      }
    } catch (e) {
      debugPrint("Device Info Error: $e");
      // If everything fails, use the cache we saved earlier
      _loadDeviceFromCache();
    }
  }

  // 🟢 LOGIC: Toggle Screen Security
  Future<void> _toggleScreenSecurity(bool enable) async {
    // 🟢 No longer needs setState here, the ValueListenableBuilder handles it!
    await UserData.toggleSecuritySetting('hideContentEnabled', enable);
    HapticFeedback.mediumImpact();
  }

  Future<void> _toggleAppLock(bool enable) async {
    isBypassingLock = true;
    bool authenticated = await _localAuth.authenticate(
      localizedReason: 'Authenticate to change App Lock settings',
      options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
    );
    isBypassingLock = false;

    if (authenticated) {
      // 🟢 Simply update the global state. ValueListenableBuilder handles the UI refresh.
      await UserData.toggleSecuritySetting('appLockEnabled', enable);
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _handle2FAToggle(bool enable) async {
    if (enable) {
      // 1. Show a glass dialog to "Verify Phone/Email"
      // 2. If verified, save state
      await UserData.toggleSecuritySetting('twoFactorEnabled', true);
      _showSuccessToast("2FA Activated");
    } else {
      // 🟢 Security: Ask for Biometrics before disabling 2FA!
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Confirm identity to disable 2FA',
      );
      if (authenticated) {
        await UserData.toggleSecuritySetting('twoFactorEnabled', false);
        _showSuccessToast("2FA Disabled");
      }
    }
  }

  // 🟢 LOGIC: Opens native phone settings
  // 🟢 REAL LOGIC: Opens the specific settings page for your app
  Future<void> _openAppSettings() async {
    bool opened = await openAppSettings();
    if (opened) {
      HapticFeedback.lightImpact();
      debugPrint("App Settings opened successfully.");
    } else {
      debugPrint("Could not open app settings.");
    }
  }

  // 🟢 LOGIC: Calculates the size of temporary files
  Future<void> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalSize = 0;
      if (tempDir.existsSync()) {
        tempDir.listSync(recursive: true).forEach((file) {
          if (file is File) totalSize += file.lengthSync();
        });
      }
      setState(() => _cacheSize = "${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB");
    } catch (e) {
      setState(() => _cacheSize = "0.0 MB");
    }
  }

  // 🟢 LOGIC: Clears the cache
  // 🟢 LOGIC: Clears the cache
  Future<void> _clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      _calculateCacheSize();

      HapticFeedback.mediumImpact();

      // 🟢 USE THE NEW PREMIUM TOAST
      _showSuccessToast("Cache cleared successfully");

    } catch (e) {
      debugPrint("Clear cache error: $e");
    }
  }

  void _showSuccessToast(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // First, clear any existing snackbars so they don't stack up
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent, // 🟢 Hides the "ugly" default box
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 20), // 🟢 Floats it above the bottom
        content: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // 🟢 Matching glass blur
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.green.withOpacity(0.15)
                    : Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF262626) : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("Privacy & Security",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Inter')),
        leading: IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: Colors.grey, size: 24),
            onPressed: () => Navigator.pop(context)
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("SECURITY",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontFamily: 'Inter',
                )),
            const SizedBox(height: 12),

            // 1. Expanding App Lock Section
            _buildAppLockSection(isDark, cardColor),

            const SizedBox(height: 16),

            // 2. Secondary Settings Container
            // Inside your build method, in the second Container:
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  // 1. Hide in App Switcher
                  ValueListenableBuilder<bool>(
                    valueListenable: UserData.hideContentEnabled,
                    builder: (context, val, _) => _buildToggleTile(
                        isDark, HugeIcons.strokeRoundedViewOffSlash, "Hide in App Switcher", val,
                            (newVal) => _toggleScreenSecurity(newVal)
                    ),
                  ),
                  _buildDivider(isDark),

                  // 2. Location Services (Synced)
                  ValueListenableBuilder<bool>(
                    valueListenable: UserData.locationEnabled,
                    builder: (context, val, _) => _buildToggleTile(
                        isDark, HugeIcons.strokeRoundedLocation01, "Location Services", val,
                            (newVal) => UserData.toggleSecuritySetting('locationEnabled', newVal)
                    ),
                  ),
                  _buildDivider(isDark),

                  // 3. Two-Factor Authentication (Correct Notifier)
                  ValueListenableBuilder<bool>(
                    valueListenable: UserData.twoFactorEnabled,
                    builder: (context, val, _) => _buildToggleTile(
                        isDark, HugeIcons.strokeRoundedSmartPhone01, "Two-Factor Authentication", val,
                            (newVal) => _handle2FAToggle(newVal)
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- 🟢 DATA & PRIVACY SECTION ---
            _buildSectionHeader("DATA & PRIVACY"),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    isDark,
                    HugeIcons.strokeRoundedSettings02,
                    "System Permissions",
                    subtitle: "Manage Camera, Gallery, and GPS",
                    onTap: _openAppSettings,
                  ),
                  _buildDivider(isDark),
                  _buildSettingsTile(
                    isDark,
                    HugeIcons.strokeRoundedDelete02,
                    "Clear App Cache",
                    subtitle: "Free up storage space",
                    trailing: Text(_cacheSize, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                    onTap: () => _showClearCacheConfirmation(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- 🟢 SESSIONS SECTION ---
            _buildSectionHeader("ACTIVE SESSIONS"),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  // 🟢 Reactive Device Tile: Syncs with GPS Refresh from Profile
                  // Inside Column for ACTIVE SESSIONS
                  ValueListenableBuilder<String>(
                    valueListenable: UserData.userLocation,
                    builder: (context, location, _) {
                      return _buildCurrentDeviceTile(isDark, location);
                    },
                  ),
                  _buildDivider(isDark),
                  _buildSettingsTile(
                    isDark, HugeIcons.strokeRoundedShield02, "Log out of all devices",
                    subtitle: "Instantly secure your account",
                    onTap: () => _showLogoutConfirmation(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
    );
  }

  Widget _buildSettingsTile(bool isDark, dynamic icon, String title, {String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12)
                ),
                child: HugeIcon(icon: icon, color: isDark ? Colors.white : Colors.black87, size: 20)
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                  if (subtitle != null)
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Inter')),
                ],
              ),
            ),
            if (trailing != null) trailing else const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildAppLockSection(bool isDark, Color cardColor) {
    return ValueListenableBuilder<bool>(
      valueListenable: UserData.appLockEnabled,
      builder: (context, appLockEnabled, _) {
        return ValueListenableBuilder<int>(
          valueListenable: UserData.appLockTimeout,
          builder: (context, timeoutValue, _) {
            String currentTimeoutText = timeoutValue == 0 ? "Immediately" : "After $timeoutValue min";
            if (timeoutValue == 60) currentTimeoutText = "After 1 hour";

            return Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (appLockEnabled) {
                        setState(() => _isTimeoutExpanded = !_isTimeoutExpanded);
                        HapticFeedback.selectionClick();
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: appLockEnabled ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: HugeIcon(
                                icon: HugeIcons.strokeRoundedLockKey,
                                color: appLockEnabled ? Colors.blue : Colors.grey,
                                size: 20
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("App Lock", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                                const SizedBox(height: 2),
                                Text(
                                  appLockEnabled ? "Enabled • $currentTimeoutText" : "Disabled",
                                  style: TextStyle(
                                      color: appLockEnabled ? Colors.blue : Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter'
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (appLockEnabled)
                            RotationTransition(
                              turns: AlwaysStoppedAnimation(_isTimeoutExpanded ? 0.5 : 0.0),
                              child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey, size: 22),
                            ),
                          const SizedBox(width: 8),
                          Switch.adaptive(
                            value: appLockEnabled,
                            activeColor: Colors.blue,
                            onChanged: (val) {
                              _toggleAppLock(val);
                              if (!val) setState(() => _isTimeoutExpanded = false);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: Column(
                      children: [
                        Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 20, endIndent: 20),
                        const SizedBox(height: 8),
                        _buildModernOption("Immediately", 0, isDark, timeoutValue),
                        _buildModernOption("After 1 minute", 1, isDark, timeoutValue),
                        _buildModernOption("After 15 minutes", 15, isDark, timeoutValue),
                        _buildModernOption("After 1 hour", 60, isDark, timeoutValue),
                        const SizedBox(height: 12),
                      ],
                    ),
                    crossFadeState: (appLockEnabled && _isTimeoutExpanded) ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModernOption(String title, int value, bool isDark, int currentSelected) {
    bool isSelected = currentSelected == value;

    return GestureDetector(
      onTap: () async {
        // 🟢 FIXED: Updates global state and local disk simultaneously
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('appLockTimeout', value);
        UserData.appLockTimeout.value = value;
        HapticFeedback.lightImpact();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 24),
        child: Row(
          children: [
            const SizedBox(width: 46),
            Expanded(
              child: Text(
                  title,
                  style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.grey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                  )
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: Colors.blue, size: 22),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile(bool isDark, dynamic icon, String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12)
              ),
              child: HugeIcon(icon: icon, color: isDark ? Colors.white : Colors.black87, size: 20)
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'))),
          Switch.adaptive(value: value, activeColor: Colors.blue, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12, indent: 64);

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontFamily: 'Inter',
          )),
    );
  }

  Widget _buildCurrentDeviceTile(bool isDark, String syncedLocation) {
    return InkWell(
      onTap: () => _showCurrentDeviceDetails(context),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(12)),
                child: HugeIcon(icon: Platform.isAndroid ? HugeIcons.strokeRoundedAndroid : HugeIcons.strokeRoundedApple, color: isDark ? Colors.white : Colors.black87, size: 20)
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(_deviceName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      // 🟢 The Green Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: const Text("THIS DEVICE", style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 🟢 Reactive location text
                  Text("Active Now  •  $syncedLocation", style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Inter')),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 12),
          ],
        ),
      ),
    );
  }

  void _showCurrentDeviceDetails(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- 🟢 Device Icon ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                      icon: Platform.isAndroid ? HugeIcons.strokeRoundedAndroid : HugeIcons.strokeRoundedApple,
                      color: Colors.blueAccent,
                      size: 32
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Device Details",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Inter', color: isDark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 24),

                // --- 🟢 Details List ---
                _buildDetailRow("Model", _deviceName, isDark),
                _buildDivider(isDark),
                _buildDetailRow("Location", "$_currentCity, $_currentCountry", isDark),
                _buildDivider(isDark),
                _buildDetailRow("Status", "Online", isDark, isStatus: true),

                const SizedBox(height: 32),

                // --- 🟢 Close Button ---
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Done",
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper for the Details Rows
  Widget _buildDetailRow(String label, String value, bool isDark, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Inter')),
          Row(
            children: [
              if (isStatus) ...[
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                const SizedBox(width: 8),
              ],
              Text(
                value,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    color: isDark ? Colors.white : Colors.black87
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedShield02,
                      color: Colors.redAccent,
                      size: 28
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Secure Account?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "This will instantly log you out of all other devices. You will stay logged in on this Samsung phone.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: Colors.redAccent.withOpacity(0.1),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Close Dialog

                          // 🟢 THE LOGIC
                          HapticFeedback.heavyImpact();

                          // Simulate Supabase/Auth logout here...

                          // 🟢 SHOW THE GLASS TOAST
                          _showSuccessToast("Other sessions secured successfully");
                        },
                        child: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClearCacheConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🟢 Storage Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedDelete02,
                      color: Colors.blueAccent,
                      size: 28
                  ),
                ),
                const SizedBox(height: 20),

                // 🟢 Title
                Text(
                  "Clear App Cache?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // 🟢 Content
                Text(
                  "This will remove temporary files used by Rezrv to speed up loading. Your personal data and account settings will not be affected.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 28),

                // 🟢 Actions
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter'
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: Colors.blueAccent.withOpacity(0.1),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Close dialog first
                          _clearCache(); // Run your existing clear logic
                        },
                        child: const Text(
                          "Clear",
                          style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter'
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
