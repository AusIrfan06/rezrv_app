import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

// ==========================================
// SHARED UI HELPERS (Support)
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
        child: Container(width: 350, height: 350, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent.withValues(alpha: isDark ? 0.08 : 0.15))),
      ),
      Positioned(
        bottom: 100, left: -100,
        child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purpleAccent.withValues(alpha: isDark ? 0.06 : 0.12))),
      ),
    ],
  );
}

// ==========================================
// HELP CENTER SCREEN
// ==========================================
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});
  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final List<Map<String, String>> faqs = [
    {"q": "How do I book an appointment?", "a": "Simply browse for a service provider, select your preferred date and time, choose any add-ons, and proceed to checkout to secure your slot."},
    {"q": "Can I cancel or reschedule?", "a": "Yes, you can manage your bookings in the 'My Bookings' tab. Cancellations made at least 24 hours in advance are fully refunded."},
    {"q": "How do I add a new payment method?", "a": "Go to Profile > Payment Methods to add a new credit card or link a bank account. You can set a primary method for faster checkouts."},
    {"q": "Why does the app need my location?", "a": "We use your location to accurately display the nearest providers in your city."},
  ];

  int? expandedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        title: Text("Help Center", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
        leading: IconButton(icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: isDark ? Colors.white70 : Colors.black54, size: 24), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          _buildBackgroundGlows(isDark),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hi there,\nHow can we help?", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, height: 1.2)),
                  const SizedBox(height: 24),

                  GlassContainer(
                    useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 16.0), settings: _getGlassSettings(isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.6))),
                      child: TextField(
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: "Search for articles...", hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black26),
                          icon: const HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: Colors.grey, size: 20), border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text("FREQUENTLY ASKED", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 12),

                  ...List.generate(faqs.length, (index) {
                    bool isExpanded = expandedIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => expandedIndex = isExpanded ? null : index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: isExpanded ? 0.08 : 0.03) : Colors.white.withValues(alpha: isExpanded ? 0.6 : 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isExpanded ? Colors.blueAccent : Colors.white.withValues(alpha: isDark ? 0.05 : 0.4), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(faqs[index]["q"]!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87))),
                                Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                              ],
                            ),
                            if (isExpanded) ...[
                              const SizedBox(height: 12),
                              Text(faqs[index]["a"]!, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54, height: 1.5)),
                            ]
                          ],
                        ),
                      ),
                    );
                  })
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// CONTACT US SCREEN
// ==========================================
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        title: Text("Contact Us", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
        leading: IconButton(icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: isDark ? Colors.white70 : Colors.black54, size: 24), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          _buildBackgroundGlows(isDark),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Get in Touch", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 8),
                  Text("Our friendly team is always here to chat.", style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
                  const SizedBox(height: 32),

                  _buildContactCard(isDark, HugeIcons.strokeRoundedMessage02, "Chat to support", "We're here to help.", "Start a chat"),
                  const SizedBox(height: 16),
                  _buildContactCard(isDark, HugeIcons.strokeRoundedMail01, "Email us", "Drop us a line anytime.", "support@rezrv.com"),
                  const SizedBox(height: 16),
                  _buildContactCard(isDark, HugeIcons.strokeRoundedCall02, "Call us", "Mon-Fri from 9am to 5pm.", "+60 12-345 6789"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(bool isDark, dynamic icon, String title, String subtitle, String action) {
    return GlassContainer(
      useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 20.0), settings: _getGlassSettings(isDark),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.6))),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: HugeIcon(icon: icon, color: Colors.blueAccent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                  const SizedBox(height: 8),
                  Text(action, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueAccent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}