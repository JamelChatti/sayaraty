// lib/features/settings/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme_provider.dart';
import '../../application/settings_service.dart';
import '../../domain/app_settings.dart';
import '../widgets/hide_apps_sheet.dart';


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

  Future<void> _saveSettings() async {
    await ref.read(appSettingsProvider.notifier).save(_settings);
  }

  Future<void> _openWebPage(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir la page')),
      );
    }
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
            subtitle: Text(
              _settings.currency == CurrencyEnum.tnd
                  ? 'TND — saisie en millimes, affichage en dinars'
                  : 'Actuelle : ${_settings.currency.name.toUpperCase()}',
            ),
            trailing: DropdownButton<CurrencyEnum>(
              value: _settings.currency,
              items: CurrencyEnum.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _settings = _settings.copyWith(currency: v));
                await _saveSettings();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Devise : ${v.name.toUpperCase()} — appliquée dans toute l’application',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),

          GestureDetector(
            onDoubleTap: () => showHideAppsSheet(context),
            child: ListTile(
              leading: const Icon(Icons.apps),
              title: const Text('Autres'),
              subtitle: const Text('Double-tapez pour masquer des icônes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Bienvenue'),
                    content: const Text('Coming soon'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Supprimer le compte'),
            subtitle: const Text('Demander la suppression du compte et des données'),
            onTap: () => _openWebPage(
              context,
              'https://jamelchatti.github.io/sayaraty/suppression-compte.html',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Règles de confidentialité'),
            subtitle: const Text('Comment Sayaraty traite vos données'),
            onTap: () => _openWebPage(
              context,
              'https://jamelchatti.github.io/sayaraty/privacy.html',
            ),
          ),

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