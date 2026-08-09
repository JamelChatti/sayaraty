import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/app_settings.dart';
import 'settings_service.dart';

final currencyProvider = Provider<CurrencyEnum>((ref) {
  final settingsAsync = ref.watch(appSettingsProvider);
  return settingsAsync.asData?.value.currency ?? CurrencyEnum.eur;
});
