// lib/features/settings/application/settings_service.dart
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';


final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  final service = ref.watch(settingsServiceProvider);
  return service.loadSettings();
});

class SettingsService {
  static const _key = 'app_settings';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return const AppSettings();
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return AppSettings.fromMap(map);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(settings.toMap());
    //await prefs.setString(_key, jsonString);
    await prefs.setString('app_settings', jsonString);
  }

  Future<void> logout() async {
    // Vous pouvez aussi vider les données utilisateur ici
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // ou seulement supprimer les clés pertinentes
    // Et déconnecter de Firebase
    await FirebaseAuth.instance.signOut();
  }
}