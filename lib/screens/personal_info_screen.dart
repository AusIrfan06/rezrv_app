import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../data/user_data.dart';
import 'package:rezrv/l10n/generated/app_localizations.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'; // 🟢 Added for the premium glass
import '../utils/glass_toast.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;

  // 🟢 NEW: Focus Nodes for interactive glowing text fields
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _dobFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: UserData.userName.value);
    _emailController = TextEditingController(text: UserData.userEmail.value);
    _phoneController = TextEditingController(text: UserData.userPhone.value);
    _dobController = TextEditingController(text: UserData.userDob.value);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _dobFocus.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    FocusScope.of(context).unfocus();

    await UserData.updateProfile(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      dob: _dobController.text,
    );

    // 🟢 Simply call your new global helper!
    if (mounted) {
      showGlassToast(context, "Profile Saved Successfully");
      Navigator.pop(context);
    }
  }

  // 🟢 Helper for standard Glass Settings
  LiquidGlassSettings _getGlassSettings(bool isDark, {double blur = 15.0}) {
    return LiquidGlassSettings(
      thickness: 0.1,
      blur: blur,
      refractiveIndex: 1.0,
      glassColor: Colors.transparent,
      lightAngle: 45.0,
      lightIntensity: isDark ? 0.1 : 0.2,
      ambientStrength: 1.0,
      saturation: 1.0,
      chromaticAberration: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasProfilePic = UserData.userProfilePic.value.isNotEmpty;

    return GestureDetector(
      // Tapping anywhere outside a text field drops the keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBodyBehindAppBar: true, // Let the background glow reach the top
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
              "Personal Info",
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black87
              )
          ),
          leading: IconButton(
              icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: isDark ? Colors.white70 : Colors.black54, size: 24),
              onPressed: () => Navigator.pop(context)
          ),
        ),
        body: Stack(
          children: [
            // 🟢 BACKGROUND GLOWS
            Positioned(
              top: -50, right: -100,
              child: Container(
                width: 350, height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent.withValues(alpha: isDark ? 0.08 : 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: 100, left: -100,
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.purpleAccent.withValues(alpha: isDark ? 0.06 : 0.12),
                ),
              ),
            ),

            // 🟢 MAIN CONTENT
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    // --- AVATAR DISPLAY ---
                    Center(
                      child: GlassContainer(
                        useOwnLayer: true,
                        quality: GlassQuality.standard,
                        shape: LiquidRoundedSuperellipse(borderRadius: 100.0),
                        settings: _getGlassSettings(isDark, blur: 20),
                        child: Container(
                          width: 120, height: 120,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4),
                              border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.5), width: 1.5)
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: isDark ? Colors.black26 : Colors.black12,
                            backgroundImage: hasProfilePic
                                ? (UserData.userProfilePic.value.startsWith('http')
                                ? NetworkImage(UserData.userProfilePic.value) as ImageProvider
                                : FileImage(File(UserData.userProfilePic.value)) as ImageProvider)
                                : null,
                            child: !hasProfilePic ? const HugeIcon(icon: HugeIcons.strokeRoundedUser, color: Colors.grey, size: 40) : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                        "Your Profile Data",
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)
                    ),
                    const SizedBox(height: 40),

                    // --- ADVANCED TEXT FIELDS ---
                    _buildAdvancedTextField(
                        isDark: isDark,
                        label: "Full Name",
                        hint: "Enter your full name",
                        controller: _nameController,
                        icon: HugeIcons.strokeRoundedUser,
                        focusNode: _nameFocus
                    ),
                    const SizedBox(height: 20),
                    _buildAdvancedTextField(
                        isDark: isDark,
                        label: "Email Address",
                        hint: "Enter your email",
                        controller: _emailController,
                        icon: HugeIcons.strokeRoundedMail01,
                        focusNode: _emailFocus
                    ),
                    const SizedBox(height: 20),
                    _buildAdvancedTextField(
                        isDark: isDark,
                        label: "Phone Number",
                        hint: "Enter your phone number",
                        controller: _phoneController,
                        icon: HugeIcons.strokeRoundedSmartPhone01,
                        focusNode: _phoneFocus
                    ),
                    const SizedBox(height: 20),
                    _buildAdvancedTextField(
                        isDark: isDark,
                        label: "Date of Birth",
                        hint: "DD / MM / YYYY",
                        controller: _dobController,
                        icon: HugeIcons.strokeRoundedCalendar01,
                        focusNode: _dobFocus
                    ),

                    const SizedBox(height: 48),

                    // --- PREMIUM SAVE BUTTON ---
                    _AnimatedPressable(
                      onTap: _saveChanges,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))
                            ]
                        ),
                        child: const Center(
                            child: Text(
                                "Save Changes",
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                            )
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 NEW: Interactive Glass Text Field Builder
  Widget _buildAdvancedTextField({
    required bool isDark,
    required String label,
    required String hint,
    required TextEditingController controller,
    required dynamic icon,
    required FocusNode focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
              label.toUpperCase(),
              style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2
              )
          ),
        ),
        GlassContainer(
          useOwnLayer: true,
          quality: GlassQuality.standard,
          shape: LiquidRoundedSuperellipse(borderRadius: 16.0),
          settings: _getGlassSettings(isDark, blur: 15),

          // AnimatedBuilder listens to the FocusNode to change colors instantly when tapped!
          child: AnimatedBuilder(
              animation: focusNode,
              builder: (context, child) {
                final isFocused = focusNode.hasFocus;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: isFocused ? 0.08 : 0.03)
                        : Colors.white.withValues(alpha: isFocused ? 0.7 : 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isFocused
                          ? Colors.blueAccent
                          : Colors.white.withValues(alpha: isDark ? 0.1 : 0.6),
                      width: isFocused ? 1.5 : 1.0,
                    ),
                  ),
                  child: TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 15
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                          color: isDark ? Colors.white30 : Colors.black26,
                          fontWeight: FontWeight.normal
                      ),
                      icon: HugeIcon(
                          icon: icon,
                          color: isFocused ? Colors.blueAccent : (isDark ? Colors.white54 : Colors.black45),
                          size: 22
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                );
              }
          ),
        ),
      ],
    );
  }
}

// --- SHARED ANIMATION WRAPPER ---
class _AnimatedPressable extends StatefulWidget {
  final Widget child; final VoidCallback onTap;
  const _AnimatedPressable({required this.child, required this.onTap});
  @override
  State<_AnimatedPressable> createState() => _AnimatedPressableState();
}
class _AnimatedPressableState extends State<_AnimatedPressable> with SingleTickerProviderStateMixin {
  late AnimationController _c; late Animation<double> _s;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100)); _s = Tween<double>(begin: 1.0, end: 0.94).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut)); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) { return GestureDetector(onTapDown: (_) => _c.forward(), onTapUp: (_) { _c.reverse(); widget.onTap(); }, onTapCancel: () => _c.reverse(), child: ScaleTransition(scale: _s, child: widget.child)); }
}