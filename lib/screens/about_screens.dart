import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

// ==========================================
// SHARED UI HELPERS (About)
// ==========================================
LiquidGlassSettings _getGlassSettings(bool isDark, {double blur = 15.0}) {
  return LiquidGlassSettings(
    thickness: 0.1, blur: blur, refractiveIndex: 1.0, glassColor: Colors.transparent,
    lightAngle: 45.0, lightIntensity: isDark ? 0.1 : 0.2, ambientStrength: 1.0,
    saturation: 1.0, chromaticAberration: 0.0,
  );
}

Widget _buildBackgroundGlows(bool isDark) {
  return Stack(
    children: [
      Positioned(
        top: -50, right: -100,
        child: Container(width: 350, height: 350, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent.withOpacity(isDark ? 0.08 : 0.15))),
      ),
      Positioned(
        bottom: 100, left: -100,
        child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purpleAccent.withOpacity(isDark ? 0.06 : 0.12))),
      ),
    ],
  );
}

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

// ==========================================
// REUSABLE LEGAL TEXT SCREEN (Terms & Privacy)
// ==========================================
class LegalTextScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalTextScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
        leading: IconButton(icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: isDark ? Colors.white70 : Colors.black54, size: 24), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          _buildBackgroundGlows(isDark),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GlassContainer(
                useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 24.0), settings: _getGlassSettings(isDark),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(isDark ? 0.05 : 0.6))),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(content, style: TextStyle(fontSize: 14, height: 1.6, color: isDark ? Colors.white70 : Colors.black87)),
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

// Pre-defined Legal Texts for Rezrv
const String rezrvTermsText = """
Last Updated: March 2026

Welcome to Rezrv. By accessing or using our mobile application to discover and book appointments with service providers, you agree to be bound by these Terms of Service.

1. Account Registration
You must create an account to book services. You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account.

2. Booking and Cancellations
When you book an appointment, you commit to arriving at the designated time. Cancellations must be made within the provider's specified cancellation window (typically 24 hours). Late cancellations may incur a fee.

3. Payments
Prices shown on the app are in Malaysian Ringgit (MYR). By adding a payment method, you authorize Rezrv and our third-party payment processors to charge your selected method for booked services.

4. Provider Services
Rezrv acts as a platform connecting you with independent service providers. We are not responsible for the quality, safety, or legality of the services provided by third parties.
""";

const String rezrvPrivacyText = """
Last Updated: March 2026

Your privacy is important to Rezrv. This policy explains how we collect and use your data.

1. Information We Collect
We collect information you provide directly, such as your name, email, phone number, and payment details. 

2. Location Services
With your permission, we collect your device's precise location (City and State) to show you the nearest service providers and calculate accurate travel estimates. You can disable location services at any time in the app's Privacy & Security settings.

3. How We Use Your Data
We use your data to process bookings, facilitate payments, and improve the app experience. Your payment information is encrypted and stored securely using industry-standard protocols.

4. Sharing of Information
We share your name and appointment details with the specific service provider you book with. We do not sell your personal data to third parties.
""";

// ==========================================
// RATE THE APP SCREEN
// ==========================================
class RateAppScreen extends StatefulWidget {
  const RateAppScreen({super.key});
  @override
  State<RateAppScreen> createState() => _RateAppScreenState();
}

class _RateAppScreenState extends State<RateAppScreen> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  void _submitFeedback() {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Thank you for your feedback!", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade600, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), margin: const EdgeInsets.all(24),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent, elevation: 0,
          leading: IconButton(icon: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: isDark ? Colors.white70 : Colors.black54, size: 24), onPressed: () => Navigator.pop(context)),
        ),
        body: Stack(
          children: [
            _buildBackgroundGlows(isDark),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const HugeIcon(icon: HugeIcons.strokeRoundedStar, color: Colors.orangeAccent, size: 60),
                    const SizedBox(height: 24),
                    Text("Enjoying Rezrv?", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 8),
                    Text("Tap a star to rate it on the App Store.", style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => setState(() => _rating = index + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: index < _rating ? Colors.orangeAccent : Colors.grey.withOpacity(0.5), size: 40,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    AnimatedOpacity(
                      opacity: _rating > 0 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: GlassContainer(
                        useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 20.0), settings: _getGlassSettings(isDark),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.6))),
                          child: TextField(
                            controller: _feedbackController, maxLines: 4,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                            decoration: InputDecoration(hintText: "Tell us what you love or what we could improve...", hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black26), border: InputBorder.none),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    AnimatedOpacity(
                      opacity: _rating > 0 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: _AnimatedPressable(
                        onTap: _rating > 0 ? _submitFeedback : () {},
                        child: Container(
                          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF1976D2)]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))]),
                          child: const Center(child: Text("Submit Review", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}