import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  // Notifier agar seluruh aplikasi tahu kalau tema berubah
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.light,
  );

  // 1. Load tema saat aplikasi dibuka
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? false; // Default Light
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  // 2. Fungsi ganti tema
  static Future<void> toggle(bool isDark) async {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isDark); // Simpan ke memori HP
  }
}
