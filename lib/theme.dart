import 'package:flutter/material.dart';

final themeNotifier = ValueNotifier(ThemeMode.light);

extension ThemeNotifierExtension on ValueNotifier<ThemeMode> {
  void toggleTheme(bool isDarkMode) {
    value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }
}
