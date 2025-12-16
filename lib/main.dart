import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme_provider.dart';
import 'features/settings/application/settings_service.dart';
import 'features/settings/domain/app_settings.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // ✅ Charger les paramètres
  final settingsService = SettingsService();
  final settings = await settingsService.loadSettings();

  // ✅ Initialiser le provider de thème avec la valeur sauvegardée
  final initialThemeMode = _mapToThemeMode(settings.themeMode);
  runApp(
    ProviderScope(
      overrides: [
        // 👇 Force l'état initial du provider
        themeModeProvider.overrideWith((ref) => initialThemeMode),
      ],
      child: MyApp(),
    ),
  );
}

ThemeMode _mapToThemeMode(ThemeModeEnum e) {
  switch (e) {
    case ThemeModeEnum.light: return ThemeMode.light;
    case ThemeModeEnum.dark: return ThemeMode.dark;
    case ThemeModeEnum.system: return ThemeMode.system;
  }
}


class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      routerConfig: router,
      title: 'Gestion Entretien',
      themeMode: themeMode, // 👈 Appliquez le mode
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      debugShowCheckedModeBanner: false,
    );
  }
}