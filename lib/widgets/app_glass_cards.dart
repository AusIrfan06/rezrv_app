import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class AppGlassStyles {
  /// The global liquid glass settings used for both primary and inner cards
  static LiquidGlassSettings getGlassSettings(bool isDark) {
    return isDark
        ? LiquidGlassSettings(
      thickness: 0.1,
      blur: 2.0, // Crystal clear base blur
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
      blur: 2.0, // Crystal clear base blur
      refractiveIndex: 1.0,
      glassColor: Colors.transparent,
      lightAngle: 45.0,
      lightIntensity: 0.2,
      ambientStrength: 1.0,
      saturation: 1.0,
      chromaticAberration: 0.0,
    );
  }
}

// =========================================================================
// 1. PRIMARY GLASS CONTAINER (For Search Bars, Bottom Panels, GPS Buttons)
// =========================================================================
class PrimaryGlassContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;
  final Color? backgroundColor;

  const PrimaryGlassContainer({
    super.key,
    required this.child,
    this.radius = 24.0,
    this.padding,
    this.height,
    this.width,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: radius),
      settings: AppGlassStyles.getGlassSettings(isDark),
      child: Container(
        height: height,
        width: width,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          // If no color is passed, it remains 100% crystal clear
          color: backgroundColor,
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.4),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// =========================================================================
// 2. INNER GLASS CARD (For Stats, Hours, Buttons nested inside sheets)
// =========================================================================
class InnerGlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final Color? overrideColor;
  final Color? overrideBorderColor;

  const InnerGlassCard({
    super.key,
    required this.child,
    this.radius = 16.0,
    this.padding,
    this.overrideColor,
    this.overrideBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: radius),
      settings: AppGlassStyles.getGlassSettings(isDark),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          // Default sheer tint so it visibly pops out from a clear parent sheet
          color: overrideColor ?? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.2)),
          border: Border.all(
            color: overrideBorderColor ?? Colors.white.withValues(alpha: isDark ? 0.15 : 0.4),
            width: 1.0,
          ),
          // Softer, tighter shadow for nested elements
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}