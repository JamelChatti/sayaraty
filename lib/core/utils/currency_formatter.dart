// lib/core/utils/currency_formatter.dart
import 'package:intl/intl.dart';

import '../../features/settings/domain/app_settings.dart';

String formatCurrency(double amount, CurrencyEnum currency) {
  final NumberFormat formatter = NumberFormat.currency(
    customPattern: '#,##0.00 ¤',
    locale: _getLocale(currency),
  );
  return formatter.format(amount);
}

String _getLocale(CurrencyEnum currency) {
  switch (currency) {
    case CurrencyEnum.dzd: return 'fr-DZ';
    case CurrencyEnum.tnd: return 'fr-TN';
    case CurrencyEnum.eur: return 'fr-FR';
    case CurrencyEnum.usd: return 'en-US';
    case CurrencyEnum.gbp: return 'fr-GBP';
    case CurrencyEnum.mad: return 'fr-MAD';
    case CurrencyEnum.sar: return 'fr-SAR';
    case CurrencyEnum.qar: return 'en-QAR';
  }
}