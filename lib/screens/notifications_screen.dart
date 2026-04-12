import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../data/notification_data.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  LiquidGlassSettings _getGlassSettings(bool isDark, {double blur = 15.0}) {
    return LiquidGlassSettings(
      thickness: 0.1, blur: blur, refractiveIndex: 1.0, glassColor: Colors.transparent,
      lightAngle: 45.0, lightIntensity: isDark ? 0.1 : 0.2, ambientStrength: 1.0, saturation: 1.0, chromaticAberration: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        title: Text("Notifications", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: isDark ? Colors.white70 : Colors.black54, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: NotificationData.notifications,
              builder: (context, notifs, _) {
                final hasUnread = notifs.any((n) => n["isUnread"] == true);
                if (!hasUnread) return const SizedBox.shrink();
                return IconButton(
                  // 🟢 FIXED: Using standard icon to prevent HugeIcon missing member error
                  icon: const Icon(Icons.checklist_rounded, color: Colors.blueAccent, size: 26),
                  tooltip: "Mark all as read",
                  onPressed: NotificationData.markAllAsRead,
                );
              }
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(top: -50, right: -100, child: Container(width: 350, height: 350, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent.withValues(alpha: isDark ? 0.08 : 0.15)))),
          Positioned(bottom: 100, left: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purpleAccent.withValues(alpha: isDark ? 0.06 : 0.12)))),

          SafeArea(
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: NotificationData.notifications,
                builder: (context, notifs, _) {
                  if (notifs.isEmpty) return _buildEmptyState(isDark);

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 16, bottom: 40, left: 20, right: 20),
                    itemCount: notifs.length,
                    itemBuilder: (context, index) => _buildNotificationCard(notifs[index], isDark),
                  );
                }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif, bool isDark) {
    final bool isUnread = notif["isUnread"];

    // 🟢 FIXED: Changed to 'dynamic' so it accepts HugeIcons without crashing
    dynamic iconData;
    Color iconColor;
    Color iconBgColor;

    switch (notif["type"]) {
      case "booking":
        iconData = HugeIcons.strokeRoundedCalendar01;
        iconColor = Colors.green;
        iconBgColor = Colors.green.withValues(alpha: 0.15);
        break;
      case "promo":
        iconData = HugeIcons.strokeRoundedTag01;
        iconColor = Colors.orangeAccent;
        iconBgColor = Colors.orangeAccent.withValues(alpha: 0.15);
        break;
      default:
        iconData = HugeIcons.strokeRoundedShield01;
        iconColor = Colors.blueAccent;
        iconBgColor = Colors.blueAccent.withValues(alpha: 0.15);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Dismissible(
        key: Key(notif["id"]),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => NotificationData.removeNotification(notif["id"]),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(20)),
          child: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02, color: Colors.white, size: 24),
        ),
        child: GlassContainer(
          useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 20.0), settings: _getGlassSettings(isDark, blur: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: isUnread ? 0.08 : 0.03) : Colors.white.withValues(alpha: isUnread ? 0.7 : 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isUnread ? Colors.blueAccent.withValues(alpha: isDark ? 0.5 : 0.8) : Colors.white.withValues(alpha: isDark ? 0.1 : 0.6), width: isUnread ? 1.5 : 1.0),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                  child: HugeIcon(icon: iconData, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(notif["title"], style: TextStyle(fontSize: 15, fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600, color: isDark ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Text(notif["time"], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isUnread ? Colors.blueAccent : Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(notif["message"], style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? Colors.white70 : Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03), shape: BoxShape.circle),
            child: HugeIcon(icon: HugeIcons.strokeRoundedNotificationOff01, color: isDark ? Colors.white30 : Colors.black26, size: 60),
          ),
          const SizedBox(height: 24),
          Text("All Caught Up!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text("You don't have any new notifications.", style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.black54)),
        ],
      ),
    );
  }
}