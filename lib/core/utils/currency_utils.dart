import '../../features/settings/domain/app_settings.dart';

String currencySymbol(CurrencyEnum currency) {
  switch (currency) {
    case CurrencyEnum.dzd: return 'DA';
    case CurrencyEnum.eur: return '€';
    case CurrencyEnum.usd: return '\$';
    case CurrencyEnum.tnd: return 'DT';
    case CurrencyEnum.mad: return 'MAD';
    case CurrencyEnum.gbp: return '£';
    case CurrencyEnum.sar: return 'SAR';
    case CurrencyEnum.qar: return 'QAR';
  }
}
