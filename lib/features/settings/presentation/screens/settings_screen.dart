// lib/features/settings/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme_provider.dart';
import '../../application/settings_service.dart';
import '../../domain/app_settings.dart';


class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return settingsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Erreur: $err'))),
        data:  (settings) {
        return _SettingsBody(settings: settings,);
      },
    );
  }
}

class _SettingsBody extends ConsumerStatefulWidget {
  final AppSettings settings;
  const _SettingsBody({required this.settings,});

  @override
  ConsumerState<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends ConsumerState<_SettingsBody> {
  late AppSettings _settings;

  @override
  void initState() {
    _settings = widget.settings;
    super.initState();
  }

  void _saveSettings() {
    ref.read(settingsServiceProvider).saveSettings(_settings);
    // Optionnel : recharger l'UI ou appliquer les changements
  }

  ThemeMode _mapToThemeMode(ThemeModeEnum e) {
    switch (e) {
      case ThemeModeEnum.light: return ThemeMode.light;
      case ThemeModeEnum.dark: return ThemeMode.dark;
      case ThemeModeEnum.system: return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          // 🔆 Thème
          ListTile(
            title: const Text('Thème'),
            subtitle: Text(_getThemeLabel(_settings.themeMode)),
            trailing: DropdownButton<ThemeModeEnum>(
              value: _settings.themeMode,
              items: ThemeModeEnum.values.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(_getThemeLabel(e)),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _settings = _settings.copyWith(themeMode: value);
                });
                _saveSettings();
                // Mettre à jour le thème global via Riverpod
                final themeMode = _mapToThemeMode(value);
                ref.read(themeModeProvider.notifier).state = themeMode;
              },
            ),
          ),

          // 🌍 Langue
          ListTile(
            title: const Text('Langue'),
            subtitle: Text(_getLanguageLabel(_settings.language)),
            trailing: DropdownButton<LanguageEnum>(
              value: _settings.language,
              items: LanguageEnum.values.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(_getLanguageLabel(e)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(language: value!);
                });
                _saveSettings();
                // Ici, vous pouvez recharger l'application ou utiliser un système de localisation (ex: flutter_localizations)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Langue changée (rechargement nécessaire)')),
                );
              },
            ),
          ),

          // 💰 Devise
          ListTile(
            title: const Text('Devise'),
            subtitle: Text(_getCurrencyLabel(_settings.currency)),
            trailing: DropdownButton<CurrencyEnum>(
              value: _settings.currency,
              items: CurrencyEnum.values.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(_getCurrencyLabel(e)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(currency: value!);
                });
                _saveSettings();
              },
            ),
          ),

          const Divider(),

          // 🔐 Déconnexion
          ListTile(
            title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            leading: const Icon(Icons.logout, color: Colors.red),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Déconnecter')),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(settingsServiceProvider).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  String _getThemeLabel(ThemeModeEnum mode) {
    switch (mode) {
      case ThemeModeEnum.system: return 'Système';
      case ThemeModeEnum.light: return 'Clair';
      case ThemeModeEnum.dark: return 'Sombre';
    }
  }

  String _getLanguageLabel(LanguageEnum lang) {
    switch (lang) {
      case LanguageEnum.fr: return 'Français';
      case LanguageEnum.ar: return 'العربية';
      case LanguageEnum.en: return 'English';
    }
  }

  String _getCurrencyLabel(CurrencyEnum curr) {
    switch (curr) {
      case CurrencyEnum.dzd: return 'DZD';
      case CurrencyEnum.eur: return 'EUR';
      case CurrencyEnum.usd: return 'USD';
      case CurrencyEnum.tnd: return 'TND';
      case CurrencyEnum.gbp: return 'GBP';
      case CurrencyEnum.mad: return 'MAD';
      case CurrencyEnum.sar: return 'SAR';
      case CurrencyEnum.qar: return 'QAR';
    }
  }
}

extension AppSettingsCopyWith on AppSettings {
  AppSettings copyWith({
    ThemeModeEnum? themeMode,
    LanguageEnum? language,
    CurrencyEnum? currency,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      currency: currency ?? this.currency,
    );
  }
}