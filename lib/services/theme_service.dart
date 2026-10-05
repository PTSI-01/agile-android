import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const _preferenceKey = 'dark_mode_enabled';
  static final mode = ValueNotifier<ThemeMode>(ThemeMode.light);

  static Future<void> init() async {
    final preferences = await SharedPreferences.getInstance();
    mode.value = preferences.getBool(_preferenceKey) == true
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  static bool get isDark => mode.value == ThemeMode.dark;

  static Future<void> toggle() async {
    mode.value = isDark ? ThemeMode.light : ThemeMode.dark;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_preferenceKey, isDark);
  }
}
