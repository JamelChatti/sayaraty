import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme_provider.dart';
import 'features/settings/application/settings_service.dart';
import 'features/settings/domain/app_settings.dart';
import 'l10n/app_localizations.dart';


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
      child: MyApp(settings: settings),
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
  final AppSettings settings;
  const MyApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      routerConfig: router,
      title: 'Gestion Entretien',
      locale: settings.language.toLocale(), // 👈 Utilise votre LanguageEnum
      supportedLocales: const [
        Locale('fr'),
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      themeMode: themeMode, // 👈 Appliquez le mode
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      builder: (context, child) {
        return Directionality(
          textDirection: settings.language == LanguageEnum.ar
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child!,
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}