import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../maintenance/application/fuel_consumption_provider.dart';
import '../../../maintenance/domain/fuel_consumption.dart';
import '../../../settings/application/currency_provider.dart';

/// Résumé consommation carburant sur la fiche véhicule.
class FuelConsumptionSection extends ConsumerWidget {
  final String vehicleId;

  const FuelConsumptionSection({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(vehicleFuelStatsProvider(vehicleId));
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);

    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) => _FuelBody(
        stats: stats,
        currencyLabel: formatCurrency(stats.totalCost, currency),
        costPer100: stats.averageCostPer100Km != null
            ? formatCurrency(stats.averageCostPer100Km!, currency)
            : null,
        theme: theme,
      ),
    );
  }
}

class _FuelBody extends StatelessWidget {
  final FuelStats stats;
  final String currencyLabel;
  final String? costPer100;
  final ThemeData theme;

  const _FuelBody({
    required this.stats,
    required this.currencyLabel,
    required this.costPer100,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final avg = stats.averageLitersPer100Km;
    final last = stats.lastLitersPer100Km;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Consommation carburant',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: stats.numberOfFills == 0
                ? const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.local_gas_station_outlined),
                    title: Text('Aucun plein enregistré'),
                    subtitle: Text(
                      'Ajoutez un entretien « Carburant » et cochez '
                      '« Plein complet » pour calculer la conso.',
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_gas_station,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              avg != null
                                  ? '${avg.toStringAsFixed(1)} L/100 km'
                                  : 'Conso non calculable',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        avg != null
                            ? 'Moyenne sur ${stats.segments.length} trajet'
                                '${stats.segments.length > 1 ? 's' : ''} '
                                '(pleins complets)'
                            : stats.fullTankCount < 2
                                ? 'Il faut au moins 2 pleins complets '
                                    '(actuellement ${stats.fullTankCount}).'
                                : 'Vérifiez les kilométrages des pleins.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Divider(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          if (last != null)
                            _chip(
                              theme,
                              'Dernière',
                              '${last.toStringAsFixed(1)} L/100',
                            ),
                          _chip(
                            theme,
                            'Pleins',
                            '${stats.numberOfFills}',
                          ),
                          _chip(
                            theme,
                            'Litres',
                            '${stats.totalLiters.toStringAsFixed(1)} L',
                          ),
                          _chip(theme, 'Dépenses', currencyLabel),
                          if (costPer100 != null)
                            _chip(theme, 'Coût / 100 km', '$costPer100'),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _chip(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: theme.textTheme.titleSmall),
      ],
    );
  }
}
