import 'package:intl/intl.dart';
import '../../features/settings/domain/app_settings.dart';

String formatCurrency(double amount, CurrencyEnum currency) {
  // Le TND (Dinar Tunisien) utilise 3 décimales
  final int digits = (currency == CurrencyEnum.tnd) ? 3 : 2;

  final formatter = NumberFormat.currency(
    locale: _getLocale(currency),
    symbol: _getSymbol(currency),
    decimalDigits: digits,
  );

  return formatter.format(amount);
}

String _getLocale(CurrencyEnum currency) {
  switch (currency) {
    case CurrencyEnum.dzd:
    case CurrencyEnum.tnd:
    case CurrencyEnum.mad:
      return 'fr_TN'; // Utiliser fr_TN aide pour le formatage régional
    case CurrencyEnum.eur:
      return 'fr_FR';
    case CurrencyEnum.usd:
      return 'en_US';
    default:
      return 'fr';
  }
}

String _getSymbol(CurrencyEnum currency) {
  switch (currency) {
    case CurrencyEnum.dzd: return 'DA';
    case CurrencyEnum.tnd: return 'DT'; // "DT" est souvent plus commun que "TND" en Tunisie
    case CurrencyEnum.eur: return '€';
    case CurrencyEnum.usd: return '\$';
    case CurrencyEnum.gbp: return '£';
    case CurrencyEnum.mad: return 'MAD';
    case CurrencyEnum.sar: return 'SAR';
    case CurrencyEnum.qar: return 'QAR';
  }
}