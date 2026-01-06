// lib/core/localization/app_locale.dart
enum AppLocale {
  en, fr, ar;

  String get languageCode {
    switch (this) {
      case en: return 'en';
      case fr: return 'fr';
      case ar: return 'ar';
    }
  }

  static AppLocale fromString(String? value) {
    switch (value) {
      case 'en': return en;
      case 'fr': return fr;
      case 'ar': return ar;
      default: return fr; // langue par défaut
    }
  }
}