import 'package:intl/intl.dart';
import '../../features/settings/domain/app_settings.dart';
import 'currency_utils.dart';

/// Affiche un montant stocké (unité majeure) — pour le TND toujours en dinars
/// avec 3 décimales (millimes visibles via les décimales).
String formatCurrency(double amount, CurrencyEnum currency) {
  final int digits = (currency == CurrencyEnum.tnd) ? 3 : 2;

  final formatter = NumberFormat.currency(
    locale: _getLocale(currency),
    symbol: currencySymbol(currency),
    decimalDigits: digits,
  );

  return formatter.format(amount);
}

String _getLocale(CurrencyEnum currency) {
  switch (currency) {
    case CurrencyEnum.dzd:
    case CurrencyEnum.tnd:
    case CurrencyEnum.mad:
      return 'fr_TN';
    case CurrencyEnum.eur:
      return 'fr_FR';
    case CurrencyEnum.usd:
      return 'en_US';
    default:
      return 'fr';
  }
}
