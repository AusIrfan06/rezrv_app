import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ReservationDetailScreen extends StatefulWidget {
  final String title, category, imageUrl;

  const ReservationDetailScreen({
    super.key,
    required this.title,
    required this.category,
    required this.imageUrl
  });

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  late Timer _timer;
  Duration _timeLeft = const Duration(hours: 2, minutes: 45, seconds: 0);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft.inSeconds > 0) {
        setState(() => _timeLeft -= const Duration(seconds: 1));
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // LAYER 1: Background Image (Bottom)
          Container(
            height: 400,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(widget.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, bgColor],
                ),
              ),
            ),
          ),

          // LAYER 2: Scrollable Content (Middle)
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 300),

                // Your actual Glassmorphic Info Card code
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Column(
                          children: [
                            Text(widget.category.toUpperCase(), style: const TextStyle(color: Color(0xFF0052FF), fontWeight: FontWeight.bold)),
                            Text(widget.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildTime("${_timeLeft.inHours}", "Hours"),
                                _buildTime("${_timeLeft.inMinutes % 60}", "Mins"),
                                _buildTime("${_timeLeft.inSeconds % 60}", "Secs"),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                _buildInfoRow(isDark, HugeIcons.strokeRoundedCalendar01, "Saturday, March 7, 2026"),
                _buildInfoRow(isDark, HugeIcons.strokeRoundedLocation01, "Lot 4, Tapah, Perak"),

                const SizedBox(height: 16),

                // Your actual QR Code code
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF262626) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    children: [
                      HugeIcon(icon: HugeIcons.strokeRoundedQrCode01, color: Colors.blue, size: 100),
                      SizedBox(height: 8),
                      Text("Show at check-in", style: TextStyle(color: Colors.grey))
                    ],
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),

          // LAYER 3: Back Button (Top - MUST BE LAST)
          // This ensures the ScrollView doesn't block the tap
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: _buildGlassIconButton(
              isDark,
              HugeIcons.strokeRoundedArrowLeft01,
                  () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // UI COMPONENTS
  // ==========================================

  // Your Specific Glass Icon Button Format
  Widget _buildGlassIconButton(bool isDark, List<List<dynamic>> icon, VoidCallback onTap) => GestureDetector(
      onTap: onTap, // <--- CRITICAL: This must match the parameter name
      behavior: HitTestBehavior.opaque, // Ensures the entire area is clickable
      child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2))
                  ),
                  child: HugeIcon(icon: icon, color: Colors.blue, size: 24)
              )
          )
      )
  );

  Widget _buildTime(String value, String label) => Column(
    children: [
      Text(value.padLeft(2, '0'), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ],
  );

  Widget _buildInfoRow(bool isDark, List<List<dynamic>> icon, String text) => Container(
    margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF262626) : Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        HugeIcon(icon: icon, color: Colors.blue, size: 20),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}