// lib/app/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

// Provider global pour le mode thème
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  // Vous pouvez plus tard charger depuis SharedPreferences
  return ThemeMode.system;
});