import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../widgets/nav_item.dart';

// ==========================================
// CRYSTAL CLEAR NAV BAR (FLAWLESS iOS SLIDING PILL)
// ==========================================
class GlassNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<NavItem> items;

  const GlassNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items
  });

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final bool isKeyboardOpen = keyboardHeight > 100;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isKeyboardOpen ? 0.0 : 1.0,
      child: isKeyboardOpen
          ? const SizedBox.shrink()
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: GlassContainer(
          useOwnLayer: true,
          quality: GlassQuality.standard,
          shape: LiquidRoundedSuperellipse(borderRadius: 50.0),
          settings: isDark
              ? LiquidGlassSettings(
            thickness: 0.1,
            blur: 2.0, // Crystal clear
            refractiveIndex: 1.0,
            glassColor: Colors.transparent,
            lightAngle: 45.0,
            lightIntensity: 0.1,
            ambientStrength: 1.0,
            saturation: 1.0,
            chromaticAberration: 0.0,
          )
              : LiquidGlassSettings(
            thickness: 0.1,
            blur: 2.0, // Crystal clear
            refractiveIndex: 1.0,
            glassColor: Colors.transparent,
            lightAngle: 45.0,
            lightIntensity: 0.2,
            ambientStrength: 1.0,
            saturation: 1.0,
            chromaticAberration: 0.0,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.15 : 0.4),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),

            // --- THE MAGIC FLEX-MATH ENGINE ---
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double totalWidth = constraints.maxWidth;

                const int inactiveFlex = 2;
                const int activeFlex = 5;

                final int totalFlex = ((items.length - 1) * inactiveFlex) + activeFlex;

                final double inactiveWidth = totalWidth * (inactiveFlex / totalFlex);
                final double activeWidth = totalWidth * (activeFlex / totalFlex);

                final double pillLeftOffset = selectedIndex * inactiveWidth;

                return SizedBox(
                  height: 48,
                  child: Stack(
                    children: [
                      // ==========================================
                      // 1. THE SLIDING PILL BACKGROUND
                      // ==========================================
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        left: pillLeftOffset,
                        width: activeWidth,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withOpacity(isDark ? 0.2 : 0.4),
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),

                      // ==========================================
                      // 2. THE FOREGROUND ICONS (Clickable)
                      // ==========================================
                      // ==========================================
                      // 2. THE FOREGROUND ICONS (Clickable)
                      // ==========================================
                      Row(
                        children: List.generate(items.length, (i) {
                          final isSelected = selectedIndex == i;
                          final double targetWidth = isSelected ? activeWidth : inactiveWidth;

                          // 🟢 THE FIX: Simple Grey coloring for light mode, no shadows or stacks.
                          final Color itemColor = isDark
                              ? (isSelected ? Colors.white : Colors.white70)
                              : (isSelected ? Colors.grey.shade900 : Colors.grey.shade600);

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            width: targetWidth,
                            height: 48,
                            child: GestureDetector(
                              onTap: () => onItemSelected(i),
                              behavior: HitTestBehavior.opaque,
                              child: ClipRect(
                                child: OverflowBox(
                                  maxWidth: activeWidth,
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // 🟢 Back to a clean, simple icon
                                      HugeIcon(
                                        icon: items[i].icon,
                                        color: itemColor,
                                        size: 24,
                                        strokeWidth: 2.1,
                                      ),

                                      AnimatedSize(
                                        duration: const Duration(milliseconds: 350),
                                        curve: Curves.easeOutCubic,
                                        alignment: Alignment.centerLeft,
                                        child: isSelected
                                            ? Padding(
                                          padding: const EdgeInsets.only(left: 6),
                                          child: Text(
                                            items[i].title,
                                            maxLines: 1,
                                            style: TextStyle(
                                              color: itemColor,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
                                            ),
                                          ),
                                        )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}