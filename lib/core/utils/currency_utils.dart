import '../../features/settings/domain/app_settings.dart';

String currencySymbol(CurrencyEnum currency) {
  switch (currency) {
    case CurrencyEnum.dzd:
      return 'DA';
    case CurrencyEnum.eur:
      return '€';
    case CurrencyEnum.usd:
      return '\$';
    case CurrencyEnum.tnd:
      return 'DT';
    case CurrencyEnum.mad:
      return 'MAD';
    case CurrencyEnum.gbp:
      return '£';
    case CurrencyEnum.sar:
      return 'SAR';
    case CurrencyEnum.qar:
      return 'QAR';
  }
}

/// Le dinar tunisien se saisit en millimes (1 DT = 1000 millimes).
bool usesMillimeInput(CurrencyEnum currency) => currency == CurrencyEnum.tnd;

/// Suffixe affiché sur les champs de saisie monétaire.
String currencyInputSuffix(CurrencyEnum currency) =>
    usesMillimeInput(currency) ? 'millimes' : currencySymbol(currency);

/// Convertit la saisie utilisateur vers l’unité de stockage (dinar / euro…).
/// Pour le TND : millimes → dinars (`2500` → `2.5`).
double parseMoneyInput(String? text, CurrencyEnum currency) {
  if (text == null) return 0;
  final normalized = text.trim().replaceAll(',', '.').replaceAll(' ', '');
  if (normalized.isEmpty) return 0;
  final raw = double.tryParse(normalized) ?? 0;
  if (usesMillimeInput(currency)) return raw / 1000.0;
  return raw;
}

/// Préremplit un champ de saisie à partir d’un montant stocké (unité majeure).
/// Pour le TND : dinars → millimes (`2.5` → `2500`).
String formatMoneyForInput(double amount, CurrencyEnum currency) {
  if (usesMillimeInput(currency)) {
    final millimes = amount * 1000;
    if ((millimes - millimes.roundToDouble()).abs() < 0.001) {
      return millimes.round().toString();
    }
    return millimes.toStringAsFixed(0);
  }
  if (amount == amount.roundToDouble()) {
    return amount.round().toString();
  }
  return amount.toString();
}
