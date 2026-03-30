import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../services/supabase_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = false; // Starts on the Sign Up mode by default
  bool _isLoading = false;
  bool _obscurePassword = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? errorMsg;

    if (_isLogin) {
      errorMsg = await SupabaseService.signInUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } else {
      errorMsg = await SupabaseService.signUpUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (errorMsg == null) {
      // 🟢 SUCCESS! Close the auth screen and go back to the app
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLogin ? "Welcome back!" : "Account created successfully!"),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context); // Takes them back to the Profile Screen!
    } else {
      // 🔴 FAILED! Show the Supabase error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: isDark ? Colors.white : Colors.black87, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Ambient Background Blobs
          Positioned(top: -100, left: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent.withOpacity(isDark ? 0.1 : 0.2)))),
          Positioned(bottom: -50, right: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purpleAccent.withOpacity(isDark ? 0.1 : 0.2)))),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLogin ? "Welcome\nBack!" : "Create\nAccount",
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, height: 1.1, color: isDark ? Colors.white : Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isLogin ? "Sign in to manage your bookings." : "Join us to book your next appointment.",
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 40),

                    GlassContainer(
                      useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 24.0), settings: _getGlassSettings(isDark),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(24.0),
                          border: Border.all(color: Colors.white.withOpacity(isDark ? 0.15 : 0.6), width: 1.0),
                        ),
                        child: Column(
                          children: [
                            if (!_isLogin) ...[
                              _buildInputField(isDark: isDark, label: "Full Name", controller: _nameController, icon: HugeIcons.strokeRoundedUser),
                              const SizedBox(height: 16),
                            ],

                            _buildInputField(isDark: isDark, label: "Email Address", controller: _emailController, icon: HugeIcons.strokeRoundedMail01, keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 16),

                            if (!_isLogin) ...[
                              _buildInputField(isDark: isDark, label: "Phone Number", controller: _phoneController, icon: HugeIcons.strokeRoundedCall02, keyboardType: TextInputType.phone),
                              const SizedBox(height: 16),
                            ],

                            _buildInputField(
                              isDark: isDark, label: "Password", controller: _passwordController, icon: HugeIcons.strokeRoundedLockPassword,
                              isPassword: true, obscureText: _obscurePassword, onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    GestureDetector(
                      onTap: _isLoading ? null : _submitForm,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF1976D2)]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(_isLogin ? "Sign In" : "Sign Up", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Toggle Login/Signup
                    Center(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = !_isLogin),
                        behavior: HitTestBehavior.opaque,
                        child: RichText(
                          text: TextSpan(
                            text: _isLogin ? "Don't have an account? " : "Already have an account? ",
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14),
                            children: [
                              TextSpan(
                                text: _isLogin ? "Sign Up" : "Sign In",
                                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({required bool isDark, required String label, required TextEditingController controller, required dynamic icon, TextInputType keyboardType = TextInputType.text, bool isPassword = false, bool obscureText = false, VoidCallback? onToggleObscure}) {
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
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 14),
            validator: (value) => value == null || value.isEmpty ? "Required" : null,
            decoration: InputDecoration(
              prefixIcon: Padding(padding: const EdgeInsets.only(right: 14.0), child: HugeIcon(icon: icon, color: Colors.grey, size: 20)),
              prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              border: InputBorder.none,
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