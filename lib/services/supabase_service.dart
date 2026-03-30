import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/user_data.dart';

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

  // 🟢 2. SIGN IN EXISTING USER
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
    UserData.userEmail.value = '';
    UserData.userName.value = '';
    UserData.userPhone.value = '';
    UserData.userProfilePic.value = '';
  }

  // 🟢 4. CHECK IF USER IS ALREADY LOGGED IN
  static bool isUserLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  // 🟢 5. UPLOAD PROFILE PICTURE
  static Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return "User not logged in";

      final fileExtension = imageFile.path.split('.').last;
      final fileName = '${user.id}.$fileExtension';

      // 1. Upload the image to the 'avatars' bucket
      await _supabase.storage.from('avatars').upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(upsert: true),
      );
      // 2. Get the public URL of the freshly uploaded image
      String publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      // --- 🟢 CACHE BUSTER: Add a timestamp to force Flutter to reload the new image! ---
      publicUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      // 3. Save that new unique URL into the database table
      await _supabase.from('profiles').update({'avatar_url': publicUrl}).eq('id', user.id);
      // 4. Update the app's UI instantly
      UserData.userProfilePic.value = publicUrl;
      return null; // Success!
    } 
    catch (e) {
      return "Failed to upload image: $e";
    }
  }

  // 🟢 6. DELETE PROFILE PICTURE
  static Future<String?> deleteProfileImage() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return "User not logged in";

      // 1. Get the current image URL from our local state
      final currentUrl = UserData.userProfilePic.value;
      if (currentUrl.isEmpty) return null; // Nothing to delete

      // 2. Extract the file name from the URL
      // E.g., https://.../avatars/user123.png?t=123 -> user123.png
      final uri = Uri.parse(currentUrl);
      final fileName = uri.pathSegments.last;

      // 3. Delete the file from the 'avatars' storage bucket
      await _supabase.storage.from('avatars').remove([fileName]);

      // 4. Clear the avatar_url in the profiles database table
      await _supabase.from('profiles').update({'avatar_url': null}).eq('id', user.id);

      // 5. Instantly clear the UI globally
      UserData.userProfilePic.value = '';

      return null; // Success!
    } catch (e) {
      debugPrint("Delete Image Error: $e");
      return "Failed to delete image: $e";
    }
  }

  // 🟢 7. UPDATE PASSWORD
  static Future<String?> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return null; // Success
    } catch (e) {
      debugPrint("Update Password Error: $e");
      return "Failed to update password. You may need to log out and log back in to verify your session.";
    }
  }
  
  // 🟢 6. AUTO-SYNC ON STARTUP
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

        debugPrint("✅ Startup Sync Complete: ${UserData.userName.value}");
      } catch (e) {
        debugPrint("❌ Startup Sync Failed: $e");
      }
    }
  }
}