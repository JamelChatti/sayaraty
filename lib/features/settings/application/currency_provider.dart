import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/app_settings.dart';
import 'settings_service.dart';

/// Devise choisie dans les paramètres, utilisée partout dans l'app.
final currencyProvider = Provider<CurrencyEnum>((ref) {
  final settingsAsync = ref.watch(appSettingsProvider);
  return settingsAsync.asData?.value.currency ?? const AppSettings().currency;
});
