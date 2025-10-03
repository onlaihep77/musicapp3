import 'package:flutter/material.dart';

class ThemeController {
  ThemeController._();
  static final instance = ThemeController._();

  // Theme hiện tại
  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);

  void set(ThemeMode m) => mode.value = m;

  void toggle(bool isDark) =>
      mode.value = isDark ? ThemeMode.dark : ThemeMode.light;
}
