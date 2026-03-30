import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../main_screen.dart';
import 'dart:ui';



class AppLockScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;
  const AppLockScreen({super.key, this.onUnlocked});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    // 🟢 Instantly trigger FaceID/Fingerprint the moment the screen appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock Rezrv',
        options: const AuthenticationOptions(
          biometricOnly: false,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      debugPrint("Auth Error: $e");
    }

    if (authenticated) {
      // 🟢 ADD THIS: Tell main.dart we are unlocked
      widget.onUnlocked?.call();
      _goToHome();
    }
  }

  void _goToHome() {
    if (!mounted) return;

    // 🟢 Using PageRouteBuilder for a premium "Fade" transition
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 🟢 Uses your app's background color
      backgroundColor: Theme
          .of(context)
          .scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Background Decoration (Optional: adds some color depth)
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withOpacity(isDark ? 0.05 : 0.1),
              ),
            ),
          ),

          // 2. The Main Glass UI
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: MediaQuery
                      .of(context)
                      .size
                      .width * 0.85,
                  padding: const EdgeInsets.symmetric(
                      vertical: 40, horizontal: 24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors
                        .white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors
                          .white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Lock Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedLockKey,
                          color: Colors.blueAccent,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "App Locked",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Inter',
                            color: isDark ? Colors.white : Colors.black87
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Identity verification required",
                        style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.grey
                                .shade600,
                            fontSize: 14,
                            fontFamily: 'Inter'
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Unlock Button
                      // 🟢 REMOVED 'if (_appLockEnabled)'
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blueAccent.withOpacity(
                                  0.1),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _authenticate,
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedBiometricAccess,
                              color: Colors.blueAccent,
                              size: 20,
                            ),
                            label: const Text(
                              "Unlock with Biometrics",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter'
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}