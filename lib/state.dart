import 'package:flutter/material.dart';

// This must be outside of any class
final ValueNotifier<ThemeMode> appThemeNotifier = ValueNotifier(ThemeMode.system);
// lib/state.dart
final ValueNotifier<Locale> appLocaleNotifier = ValueNotifier(const Locale('en'));