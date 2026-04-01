import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../data/user_data.dart';
import '../services/supabase_service.dart';
import '../utils/glass_toast.dart';

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  // 🟢 1. ADDED NEW CONTROLLERS FOR E-COMMERCE
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;

  bool _isLoading = false;
  bool _obscureCurrentPass = true;
  bool _obscureNewPass = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: UserData.userName.value);
    _emailController = TextEditingController(text: UserData.userEmail.value);
    _phoneController = TextEditingController(text: UserData.userPhone.value);
    _dobController = TextEditingController(text: UserData.userDob.value); // 🟢 NEW
    _addressController = TextEditingController(text: UserData.userLocation.value); // 🟢 NEW
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // 🟢 2. SAVE THE NEW DATA TO GLOBAL STATE
      await UserData.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        dob: _dobController.text.trim(),
      );

      // Update location/address manually since it has a separate global notifier
      UserData.userLocation.value = _addressController.text.trim();

      final currentPass = _currentPasswordController.text.trim();
      final newPass = _newPasswordController.text.trim();

      // 🟢 3. ONLY TRIGGER PASSWORD CLOUD UPDATE IF THEY TYPED SOMETHING
      if (newPass.isNotEmpty && currentPass.isNotEmpty) {
        final passError = await SupabaseService.updatePassword(
            currentPassword: currentPass,
            newPassword: newPass
        );

        if (passError != null) {
          setState(() => _isLoading = false);
          showGlassToast(context, passError, isError: true);
          return;
        }
      }

      setState(() => _isLoading = false);

      if (mounted) {
        showGlassToast(context, "Account updated successfully!");
        Navigator.pop(context);
      }
    }
  }

  // 🟢 4. FIXED PASSWORD VALIDATION LOGIC
  String? _validateCurrentPassword(String? value) {
    // If they typed a NEW password, they MUST provide the current one
    if (_newPasswordController.text.isNotEmpty && (value == null || value.isEmpty)) {
      return "Required to change password";
    }
    return null; // Otherwise, completely optional!
  }

  String? _validateNewPassword(String? value) {
    // If they typed their CURRENT password, they MUST provide a new one
    if (_currentPasswordController.text.isNotEmpty && (value == null || value.isEmpty)) {
      return "Required to change password";
    }
    // If both are empty, ignore validation completely!
    if (value == null || value.isEmpty) {
      return null;
    }

    final regex = RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[\d\W]).{8,}$');
    if (!regex.hasMatch(value)) {
      return "8+ chars, upper, lower & number/symbol";
    }
    return null;
  }

  LiquidGlassSettings _getGlassSettings(bool isDark) {
    return LiquidGlassSettings(
      thickness: 0.1, blur: 15.0, refractiveIndex: 1.0, glassColor: Colors.transparent,
      lightAngle: 45.0, lightIntensity: isDark ? 0.1 : 0.2, ambientStrength: 1.0,
      saturation: 1.0, chromaticAberration: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("Account Details", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
        leading: IconButton(icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: isDark ? Colors.white70 : Colors.black54, size: 24), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          Positioned(top: -100, right: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent.withOpacity(isDark ? 0.05 : 0.1)))),
          Positioned(bottom: 100, left: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purpleAccent.withOpacity(isDark ? 0.05 : 0.1)))),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("PUBLIC PROFILE", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 12),

                    GlassContainer(
                      useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 24.0), settings: _getGlassSettings(isDark),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(24.0), border: Border.all(color: Colors.white.withOpacity(isDark ? 0.15 : 0.6), width: 1.0)),
                        child: Column(
                          children: [
                            _buildPremiumInput(isDark: isDark, label: "Full Name", controller: _nameController, icon: HugeIcons.strokeRoundedUser),
                            const SizedBox(height: 16),
                            _buildPremiumInput(isDark: isDark, label: "Email Address (Read Only)", controller: _emailController, icon: HugeIcons.strokeRoundedMail01, keyboardType: TextInputType.emailAddress, readOnly: true),
                            const SizedBox(height: 16),
                            _buildPremiumInput(isDark: isDark, label: "Phone Number", controller: _phoneController, icon: HugeIcons.strokeRoundedCall02, keyboardType: TextInputType.phone),
                            const SizedBox(height: 16),
                            _buildPremiumInput(isDark: isDark, label: "Date of Birth", controller: _dobController, icon: HugeIcons.strokeRoundedCalendar01, keyboardType: TextInputType.datetime), // 🟢 NEW DOB FIELD
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    Text("SHIPPING DETAILS", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 12),

                    // 🟢 5. NEW E-COMMERCE SHIPPING SECTION
                    GlassContainer(
                      useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 24.0), settings: _getGlassSettings(isDark),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(24.0), border: Border.all(color: Colors.white.withOpacity(isDark ? 0.15 : 0.6), width: 1.0)),
                        child: Column(
                          children: [
                            _buildPremiumInput(
                                isDark: isDark,
                                label: "Primary Delivery Address",
                                controller: _addressController,
                                icon: HugeIcons.strokeRoundedLocation01,
                                keyboardType: TextInputType.streetAddress
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    Text("SECURITY", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 12),

                    GlassContainer(
                      useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 24.0), settings: _getGlassSettings(isDark),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(24.0), border: Border.all(color: Colors.white.withOpacity(isDark ? 0.15 : 0.6), width: 1.0)),
                        child: Column(
                          children: [
                            _buildPremiumInput(
                              isDark: isDark, label: "Current Password", controller: _currentPasswordController, icon: HugeIcons.strokeRoundedLockPassword,
                              isPassword: true, obscureText: _obscureCurrentPass, onToggleObscure: () => setState(() => _obscureCurrentPass = !_obscureCurrentPass),
                              validator: _validateCurrentPassword, // 🟢 NOW USES CUSTOM LOGIC
                            ),
                            const SizedBox(height: 16),
                            _buildPremiumInput(
                              isDark: isDark, label: "New Password", controller: _newPasswordController, icon: HugeIcons.strokeRoundedLockKey,
                              isPassword: true, obscureText: _obscureNewPass, onToggleObscure: () => setState(() => _obscureNewPass = !_obscureNewPass),
                              validator: _validateNewPassword,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    GestureDetector(
                      onTap: _isLoading ? null : _saveChanges,
                      child: Container(
                        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF1976D2)]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumInput({required bool isDark, required String label, required TextEditingController controller, required dynamic icon, TextInputType keyboardType = TextInputType.text, bool isPassword = false, bool obscureText = false, VoidCallback? onToggleObscure, String? Function(String?)? validator, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(14)),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            readOnly: readOnly,
            style: TextStyle(color: isDark ? (readOnly ? Colors.white54 : Colors.white) : (readOnly ? Colors.black54 : Colors.black87), fontWeight: FontWeight.w600, fontSize: 14),
            // 🟢 If no custom validator is passed, it only checks if empty.
            validator: validator ?? (value) => value == null || value.isEmpty && !readOnly ? "Required" : null,
            decoration: InputDecoration(
              prefixIcon: Padding(padding: const EdgeInsets.only(right: 14.0), child: HugeIcon(icon: icon, color: Colors.grey, size: 20)),
              prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              border: InputBorder.none,
              errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
              suffixIcon: isPassword ? IconButton(
                icon: HugeIcon(icon: obscureText ? HugeIcons.strokeRoundedViewOff : HugeIcons.strokeRoundedView, color: Colors.grey, size: 20),
                onPressed: onToggleObscure,
              ) : null,
            ),
          ),
        ),
      ],
    );
  }
}