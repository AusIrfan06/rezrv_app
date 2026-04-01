import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/supabase_service.dart';

class UserData {
  static const _storage = FlutterSecureStorage();

  // 🟢 BLANK TEMPLATES: Core User Data
  static final ValueNotifier<String> userName = ValueNotifier<String>('');
  static final ValueNotifier<String> userEmail = ValueNotifier<String>('');
  static final ValueNotifier<String> userPhone = ValueNotifier<String>('');
  static final ValueNotifier<String> userProfilePic = ValueNotifier<String>('');
  static final ValueNotifier<String> userLocation = ValueNotifier<String>(''); // Used for Address
  static final ValueNotifier<String> userDob = ValueNotifier<String>('');

  // 🟢 BLANK TEMPLATES: Settings & Security
  static final ValueNotifier<bool> appLockEnabled = ValueNotifier<bool>(false);
  static final ValueNotifier<int> appLockTimeout = ValueNotifier<int>(0);
  static final ValueNotifier<bool> hideContentEnabled = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> locationEnabled = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> twoFactorEnabled = ValueNotifier<bool>(false);

  // 🟢 BLANK TEMPLATES: Payment Methods
  static final ValueNotifier<List<Map<String, dynamic>>> savedPaymentMethods = ValueNotifier<List<Map<String, dynamic>>>([]);

  // 🟢 LOAD FROM DEVICE (Only loads app settings, NOT secure cloud data)
  static Future<void> loadSavedData() async {
    try {
      final lockEnabledStr = await _storage.read(key: 'appLockEnabled');
      if (lockEnabledStr != null) appLockEnabled.value = lockEnabledStr == 'true';

      final lockTimeoutStr = await _storage.read(key: 'appLockTimeout');
      if (lockTimeoutStr != null) appLockTimeout.value = int.tryParse(lockTimeoutStr) ?? 0;

      final hideContentStr = await _storage.read(key: 'hideContentEnabled');
      if (hideContentStr != null) hideContentEnabled.value = hideContentStr == 'true';

      final locStr = await _storage.read(key: 'locationEnabled');
      if (locStr != null) locationEnabled.value = locStr == 'true';

      final twoFacStr = await _storage.read(key: 'twoFactorEnabled');
      if (twoFacStr != null) twoFactorEnabled.value = twoFacStr == 'true';
    } catch (e) {
      debugPrint("Error loading local settings: $e");
    }
  }

  // 🟢 UPDATE LOCAL STATE AND PUSH TO CLOUD
  static Future<void> updateProfile({String? name, String? email, String? phone, String? profilePic, String? dob, String? address}) async {
    if (name != null) userName.value = name;
    if (email != null) userEmail.value = email;
    if (phone != null) userPhone.value = phone;
    if (profilePic != null) userProfilePic.value = profilePic;
    if (dob != null) userDob.value = dob;
    if (address != null) userLocation.value = address;

    if (SupabaseService.isUserLoggedIn()) {
      await SupabaseService.updateProfileDetails(
        name: userName.value,
        phone: userPhone.value,
        dob: userDob.value,
        address: userLocation.value,
      );
    }
  }

  // 🟢 SECURITY TOGGLES
  static Future<void> toggleSecuritySetting(String key, bool value) async {
    if (key == 'appLockEnabled') appLockEnabled.value = value;
    if (key == 'hideContentEnabled') hideContentEnabled.value = value;
    if (key == 'locationEnabled') locationEnabled.value = value;
    if (key == 'twoFactorEnabled') twoFactorEnabled.value = value;
    await _storage.write(key: key, value: value.toString());
  }

  // 🟢 PAYMENT METHODS MANAGEMENT (Auto-syncs with the cloud!)
  static void addPaymentMethod(Map<String, dynamic> method) {
    final List<Map<String, dynamic>> currentList = List.from(savedPaymentMethods.value);
    currentList.add(method);
    savedPaymentMethods.value = currentList;
    SupabaseService.syncPaymentMethodsToCloud(currentList);
  }

  static void setPrimaryPaymentMethod(String id) {
    final List<Map<String, dynamic>> currentList = List.from(savedPaymentMethods.value);
    for (var i = 0; i < currentList.length; i++) {
      currentList[i]["isPrimary"] = (currentList[i]["id"] == id);
    }
    savedPaymentMethods.value = currentList;
    SupabaseService.syncPaymentMethodsToCloud(currentList);
  }

  static void removePaymentMethod(String id) {
    final List<Map<String, dynamic>> currentList = List.from(savedPaymentMethods.value);
    currentList.removeWhere((method) => method["id"] == id);
    savedPaymentMethods.value = currentList;
    SupabaseService.syncPaymentMethodsToCloud(currentList);
  }

  // 🟢 WIPE DATA ON LOGOUT
  static Future<void> clearUserData() async {
    userName.value = '';
    userEmail.value = '';
    userPhone.value = '';
    userProfilePic.value = '';
    userDob.value = '';
    savedPaymentMethods.value = [];
  }
}