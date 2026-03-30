import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // 🟢 Required for saving Payment Lists

class UserData {
  static const _platform = MethodChannel('com.rezrv.app/security');

  // --- Global State Notifiers ---
  static final ValueNotifier<String> userName = ValueNotifier("");
  static final ValueNotifier<String> userEmail = ValueNotifier("");
  static final ValueNotifier<String> userPhone = ValueNotifier("");
  static final ValueNotifier<String> userDob = ValueNotifier("");
  static final ValueNotifier<String> userLocation = ValueNotifier("");
  static final ValueNotifier<String> userProfilePic = ValueNotifier("");

  // Security Notifiers
  static final ValueNotifier<bool> appLockEnabled = ValueNotifier(false);
  static final ValueNotifier<int> appLockTimeout = ValueNotifier(0);
  static final ValueNotifier<bool> hideContentEnabled = ValueNotifier(false);
  static final ValueNotifier<bool> twoFactorEnabled = ValueNotifier(false);
  static final ValueNotifier<bool> locationEnabled = ValueNotifier(true);

  // Payment Notifier
  static final ValueNotifier<List<Map<String, dynamic>>> savedPaymentMethods = ValueNotifier([]);

  // 🟢 1. Load EVERYTHING from disk (Disk -> RAM)
  static Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    // Profile Data
    userName.value = prefs.getString('userName') ?? "Firdaus Irfan";
    userEmail.value = prefs.getString('userEmail') ?? "ausirfan0@gmail.com";
    userPhone.value = prefs.getString('userPhone') ?? "+60 11-1589 2468";
    userDob.value = prefs.getString('userDob') ?? "11/01/2006";
    userLocation.value = prefs.getString('userLocation') ?? "";
    userProfilePic.value = prefs.getString('userProfilePic') ?? "";

    // Security States
    appLockEnabled.value = prefs.getBool('appLockEnabled') ?? false;
    appLockTimeout.value = prefs.getInt('appLockTimeout') ?? 0;
    hideContentEnabled.value = prefs.getBool('hideContentEnabled') ?? false;
    twoFactorEnabled.value = prefs.getBool('twoFactorEnabled') ?? false;
    locationEnabled.value = prefs.getBool('locationEnabled') ?? true;

    // 🟢 Load Payment Methods (JSON String -> List)
    String? paymentsJson = prefs.getString('savedPaymentMethods');
    if (paymentsJson != null) {
      List<dynamic> decoded = jsonDecode(paymentsJson);
      savedPaymentMethods.value = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    await applySecuritySideEffects();
  }

  // 🟢 2. Update Profile & Save (RAM -> Disk)
  static Future<void> updateProfile({
    String? name, String? email, String? phone, String? dob, String? location, String? profilePic,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) { userName.value = name; await prefs.setString('userName', name); }
    if (email != null) { userEmail.value = email; await prefs.setString('userEmail', email); }
    if (phone != null) { userPhone.value = phone; await prefs.setString('userPhone', phone); }
    if (dob != null) { userDob.value = dob; await prefs.setString('userDob', dob); }
    if (location != null) { userLocation.value = location; await prefs.setString('userLocation', location); }
    if (profilePic != null) { userProfilePic.value = profilePic; await prefs.setString('userProfilePic', profilePic); }
  }

  // 🟢 3. Toggle Security & Save (RAM -> Disk)
  static Future<void> toggleSecuritySetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    if (key == 'appLockEnabled') appLockEnabled.value = value;
    if (key == 'twoFactorEnabled') twoFactorEnabled.value = value;
    if (key == 'locationEnabled') locationEnabled.value = value; // 🟢 Added missing key
    if (key == 'hideContentEnabled') {
      hideContentEnabled.value = value;
      await applySecuritySideEffects();
    }
  }

  static Future<void> applySecuritySideEffects() async {
    try {
      await _platform.invokeMethod('setSecure', {'enable': hideContentEnabled.value});
    } catch (e) {
      debugPrint("Native Security Error: $e");
    }
  }

  // --- 🟢 4. Payment Methods Persistence Helpers ---

  static Future<void> _savePaymentsToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    String encoded = jsonEncode(savedPaymentMethods.value);
    await prefs.setString('savedPaymentMethods', encoded);
  }

  static void addPaymentMethod(Map<String, dynamic> method) {
    final currentList = List<Map<String, dynamic>>.from(savedPaymentMethods.value);
    if (currentList.isEmpty) {
      method["isPrimary"] = true;
    } else if (method["isPrimary"] == true) {
      for (var m in currentList) { m["isPrimary"] = false; }
    }
    currentList.add(method);
    savedPaymentMethods.value = currentList;
    _savePaymentsToDisk(); // 🟢 Save after adding
  }

  static void removePaymentMethod(String id) {
    final currentList = List<Map<String, dynamic>>.from(savedPaymentMethods.value);
    currentList.removeWhere((m) => m["id"] == id);
    if (currentList.isNotEmpty && !currentList.any((m) => m["isPrimary"] == true)) {
      currentList[0]["isPrimary"] = true;
    }
    savedPaymentMethods.value = currentList;
    _savePaymentsToDisk(); // 🟢 Save after removing
  }

  static void setPrimaryPaymentMethod(String id) {
    final currentList = List<Map<String, dynamic>>.from(savedPaymentMethods.value);
    for (var m in currentList) { m["isPrimary"] = (m["id"] == id); }
    savedPaymentMethods.value = currentList;
    _savePaymentsToDisk(); // 🟢 Save after updating primary
  }
}