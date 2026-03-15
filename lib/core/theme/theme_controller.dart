import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'app_theme_mode';

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Default to dark; async load will update it
    _loadSaved();
    return ThemeMode.dark;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeKey);
    if (saved == 'light') {
      state = ThemeMode.light;
    } else if (saved == 'system') {
      state = ThemeMode.system;
    } else {
      state = ThemeMode.dark;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, mode.name);
  }

  void toggleDarkLight() {
    setTheme(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  bool get isDark => state == ThemeMode.dark;
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);
