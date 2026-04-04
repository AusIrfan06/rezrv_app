import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/user_data.dart';
import '../data/notification_data.dart'; // 🟢 ADD THIS so the service can update the number

class SupabaseService {
  static final _supabase = Supabase.instance.client;

  // 🟢 1. SIGN UP A NEW USER
  static Future<String?> signUpUser({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final User? user = res.user;
      if (user != null) {
        await _supabase.from('profiles').insert({
          'id': user.id,
          'full_name': fullName,
          'phone': phone,
        });

        UserData.userEmail.value = email;
        UserData.userName.value = fullName;
        UserData.userPhone.value = phone;

        return null;
      }
      return "Signup failed. Please try again.";
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint("Sign Up Error: $e");
      return e.toString();
    }
  }

  // 🟢 2. SIGN IN EXISTING USER (Pulls DOB, Address, and Payments)
  static Future<String?> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final User? user = res.user;
      if (user != null) {
        final profileData = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        UserData.userEmail.value = email;
        UserData.userName.value = profileData['full_name'] ?? 'User';
        UserData.userPhone.value = profileData['phone'] ?? '';
        UserData.userProfilePic.value = profileData['avatar_url'] ?? '';

        // 🟢 PULL NEW E-COMMERCE DATA
        UserData.userDob.value = profileData['dob'] ?? '';
        UserData.userLocation.value = profileData['address'] ?? '';

        if (profileData['payment_methods'] != null) {
          UserData.savedPaymentMethods.value = List<Map<String, dynamic>>.from(profileData['payment_methods']);
        }

        return null;
      }
      return "Login failed.";
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint("Sign In Error: $e");
      return e.toString();
    }
  }

  // 🟢 3. LOG OUT
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
    await UserData.clearUserData();
  }

  // 🟢 4. CHECK IF USER IS ALREADY LOGGED IN
  static bool isUserLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  // 🟢 5. SAVE PROFILE DETAILS TO CLOUD (Name, Phone, DOB, Address)
  static Future<String?> updateProfileDetails({
    required String name,
    required String phone,
    required String dob,
    required String address,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return "User not logged in";

      await _supabase.from('profiles').update({
        'full_name': name,
        'phone': phone,
        'dob': dob,
        'address': address,
      }).eq('id', user.id);

      return null;
    } catch (e) {
      debugPrint("Profile Update Error: $e");
      return "Failed to save profile details.";
    }
  }

  // 🟢 6. SYNC PAYMENT METHODS TO CLOUD (Saves Cards/Banks as JSONB)
  static Future<void> syncPaymentMethodsToCloud(List<Map<String, dynamic>> methods) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('profiles').update({
        'payment_methods': methods,
      }).eq('id', user.id);

    } catch (e) {
      debugPrint("Payment Sync Error: $e");
    }
  }

  // 🟢 7. AUTO-SYNC ON STARTUP (Pulls DOB, Address, and Payments)
  static Future<void> syncUserOnStartup() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final profileData = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        UserData.userEmail.value = user.email ?? '';
        UserData.userName.value = profileData['full_name'] ?? '';
        UserData.userPhone.value = profileData['phone'] ?? '';
        UserData.userProfilePic.value = profileData['avatar_url'] ?? '';

        // 🟢 PULL NEW E-COMMERCE DATA
        UserData.userDob.value = profileData['dob'] ?? '';
        UserData.userLocation.value = profileData['address'] ?? '';

        if (profileData['payment_methods'] != null) {
          UserData.savedPaymentMethods.value = List<Map<String, dynamic>>.from(profileData['payment_methods']);
        }

        debugPrint("✅ Startup Sync Complete: ${UserData.userName.value}");
      } catch (e) {
        debugPrint("❌ Startup Sync Failed: $e");
      }
    }
  }

  // 🟢 8. UPLOAD PROFILE PICTURE
  static Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return "User not logged in";

      final fileExtension = imageFile.path.split('.').last;
      final fileName = '${user.id}.$fileExtension';

      await _supabase.storage.from('avatars').upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(upsert: true),
      );

      String publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      publicUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      await _supabase.from('profiles').update({'avatar_url': publicUrl}).eq('id', user.id);
      UserData.userProfilePic.value = publicUrl;

      return null;
    } catch (e) {
      return "Failed to upload image: $e";
    }
  }

  // 🟢 9. DELETE PROFILE PICTURE
  static Future<String?> deleteProfileImage() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return "User not logged in";

      final currentUrl = UserData.userProfilePic.value;
      if (currentUrl.isEmpty) return null;

      final uri = Uri.parse(currentUrl);
      final fileName = uri.pathSegments.last;

      await _supabase.storage.from('avatars').remove([fileName]);
      await _supabase.from('profiles').update({'avatar_url': null}).eq('id', user.id);

      UserData.userProfilePic.value = '';

      return null;
    } catch (e) {
      debugPrint("Delete Image Error: $e");
      return "Failed to delete image: $e";
    }
  }

  // 🟢 10. UPDATE PASSWORD (SECURE)
  static Future<String?> updatePassword({required String currentPassword, required String newPassword}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || user.email == null) return "User not logged in";

      try {
        await _supabase.auth.signInWithPassword(email: user.email!, password: currentPassword);
      } on AuthException catch (_) {
        return "Incorrect current password.";
      }

      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      return null;
    } catch (e) {
      debugPrint("Update Password Error: $e");
      return "Failed to update password.";
    }
  }

  // 🟢 MERCHANT APP: Update Status & Notify User
  static Future<String?> updateBookingStatus({
    required String bookingId,
    required String customerUserId, // The user_id from the booking row
    required String newStatus,      // 'confirmed', 'completed', or 'cancelled'
    required String serviceName,
  }) async {
    try {
      // 1. Update the booking status
      await Supabase.instance.client.from('bookings').update({
        'status': newStatus,
      }).eq('id', bookingId);

      // 2. Draft the notification message based on the status
      String title = '';
      String message = '';

      if (newStatus == 'confirmed') {
        title = 'Booking Confirmed! ✅';
        message = 'Your appointment for $serviceName has been accepted.';
      } else if (newStatus == 'cancelled') {
        title = 'Booking Cancelled ❌';
        message = 'Unfortunately, your booking for $serviceName was declined.';
      }

      // 3. Shoot the notification to the Customer!
      if (title.isNotEmpty) {
        await Supabase.instance.client.from('notifications').insert({
          'recipient_id': customerUserId,
          'title': title,
          'message': message,
        });
      }

      return null; // Success!
    } catch (e) {
      debugPrint("Status Update Error: $e");
      return e.toString();
    }
  }
}