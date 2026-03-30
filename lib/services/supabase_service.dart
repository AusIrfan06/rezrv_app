import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/user_data.dart'; // To update your global UI state

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
      // Step 1: Create the secure Auth User
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final User? user = res.user;
      if (user != null) {
        // Step 2: Save the extra details to the 'profiles' table
        await _supabase.from('profiles').insert({
          'id': user.id, // Links directly to the secure auth table
          'full_name': fullName,
          'phone': phone,
        });

        // Step 3: Update your app's local UI state
        UserData.userEmail.value = email;
        UserData.userName.value = fullName;
        UserData.userPhone.value = phone;

        return null; // Null means success (no errors)
      }
      return "Signup failed. Please try again.";
    } on AuthException catch (e) {
      return e.message; // Returns Supabase errors (e.g. "Password too short")
    } catch (e) {
      return "An unexpected error occurred.";
    }
  }

  // 🟢 2. SIGN IN EXISTING USER
  static Future<String?> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: Authenticate
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final User? user = res.user;
      if (user != null) {
        // Step 2: Fetch their profile details
        final profileData = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        // Step 3: Update your app's local UI state
        UserData.userEmail.value = email;
        UserData.userName.value = profileData['full_name'] ?? 'User';
        UserData.userPhone.value = profileData['phone'] ?? '';

        return null; // Success!
      }
      return "Login failed.";
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unexpected error occurred.";
    }
  }

  // 🟢 3. LOG OUT
  static Future<void> signOut() async {
    await _supabase.auth.signOut();

    // Clear local data so the next person doesn't see it
    UserData.userEmail.value = '';
    UserData.userName.value = '';
    UserData.userPhone.value = '';
  }

  // 🟢 4. CHECK IF USER IS ALREADY LOGGED IN
  static bool isUserLoggedIn() {
    return _supabase.auth.currentUser != null;
  }
}