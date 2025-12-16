// lib/features/settings/domain/models/app_settings.dart
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
    this.currency = CurrencyEnum.dzd,
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
      currency: _enumFromString(CurrencyEnum.values, map['currency']),
    );
  }

  static T _enumFromString<T>(List<T> values, String? name) {
    if (name == null) return values.first;
    return values.firstWhere((v) => v.toString().split('.').last == name, orElse: () => values.first);
  }
}