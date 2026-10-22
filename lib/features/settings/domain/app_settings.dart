// lib/features/settings/domain/models/app_settings.dart
import 'dart:ui';

enum ThemeModeEnum { system, light, dark }
enum LanguageEnum { fr, ar, en }
enum CurrencyEnum { dzd, eur, usd, tnd, gbp, mad, sar, qar }

class AppSettings {
  final ThemeModeEnum themeMode;
  final LanguageEnum language;
  final CurrencyEnum currency;

  const AppSettings({
    this.themeMode = ThemeModeEnum.system,
    this.language = LanguageEnum.fr,
    this.currency = CurrencyEnum.tnd,
  });

  Map<String, dynamic> toMap() => {
    'themeMode': themeMode.name,
    'language': language.name,
    'currency': currency.name,
  };

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      themeMode: _enumFromString(ThemeModeEnum.values, map['themeMode']),
      language: _enumFromString(LanguageEnum.values, map['language']),
      currency: _enumFromString(
        CurrencyEnum.values,
        map['currency'],
        fallback: CurrencyEnum.tnd,
      ),
    );
  }

  static T _enumFromString<T>(List<T> values, String? name, {T? fallback}) {
    final defaultValue = fallback ?? values.first;
    if (name == null) return defaultValue;
    return values.firstWhere(
      (v) => v.toString().split('.').last == name,
      orElse: () => defaultValue,
    );
  }
}

// ✅ Extension déplacée HORS de la classe
extension LanguageEnumExtension on LanguageEnum {
  Locale toLocale() {
    switch (this) {
      case LanguageEnum.fr: return const Locale('fr');
      case LanguageEnum.ar: return const Locale('ar');
      case LanguageEnum.en: return const Locale('en');
    }
  }

  static LanguageEnum fromLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'ar': return LanguageEnum.ar;
      case 'en': return LanguageEnum.en;
      default: return LanguageEnum.fr;
    }
  }
}

