import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../settings/application/currency_provider.dart';
import '../../domain/models/maintenance_model.dart';

class MaintenanceDetailScreen extends ConsumerWidget {
  final Maintenance maintenance;
  final String vehicleName;

  const MaintenanceDetailScreen({
    super.key,
    required this.maintenance,
    required this.vehicleName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);
    final garageName = maintenance.garageName?.trim();
    final garageContact = maintenance.garageContact?.trim();
    final description = maintenance.description?.trim();
    final hasAdditionalInfo =
        (garageName != null && garageName.isNotEmpty) ||
        (description != null && description.isNotEmpty) ||
        maintenance.nextDueMileage != null ||
        maintenance.nextDueDate != null;

    return Scaffold(
      appBar: AppBar(title: Text(vehicleName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: theme.colorScheme.primaryContainer,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    maintenance.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatCurrency(maintenance.cost, currency),
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _infoColumn(
                        Icons.calendar_today,
                        'Date',
                        DateFormat('dd/MM/yyyy').format(maintenance.date),
                      ),
                      _infoColumn(
                        Icons.speed,
                        'Kilométrage',
                        '${maintenance.mileage.toStringAsFixed(0)} km',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (maintenance.items.isNotEmpty) ...[
            _sectionTitle(theme, 'Articles et pièces'),
            const SizedBox(height: 8),
            ...maintenance.items.map((item) {
              final priceTTC = item.priceWithTax;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    item.description.isEmpty
                        ? '${item.quantity} x ${formatCurrency(item.price, currency)} HT (TVA ${item.taxRate}%)'
                        : '${item.quantity} x ${formatCurrency(item.price, currency)} HT (TVA ${item.taxRate}%)\n'
                              'Note: ${item.description}',
                  ),
                  trailing: Text(
                    formatCurrency(priceTTC, currency),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  isThreeLine: item.description.isNotEmpty,
                ),
              );
            }),
          ],

          const SizedBox(height: 16),

          _sectionTitle(theme, 'Informations complémentaires'),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                if (!hasAdditionalInfo)
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Aucune information complémentaire'),
                  ),
                if (garageName != null && garageName.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.store),
                    title: const Text('Garage'),
                    subtitle: Text(garageName),
                    trailing: garageContact != null && garageContact.isNotEmpty
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone, color: Colors.blue),
                              Text(garageContact),
                            ],
                          )
                        : null,
                  ),
                if (description != null && description.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.notes),
                    title: const Text('Notes globales'),
                    subtitle: Text(description),
                  ),
                if (maintenance.nextDueMileage != null ||
                    maintenance.nextDueDate != null)
                  Container(
                    color:
                        (maintenance.isDueOverdue
                                ? AppTheme.overdue
                                : AppTheme.dueSoon)
                            .withValues(alpha: 0.12),
                    child: ListTile(
                      leading: Icon(
                        Icons.notifications_active,
                        color: maintenance.isDueOverdue
                            ? AppTheme.overdue
                            : AppTheme.dueSoon,
                      ),
                      title: const Text('Prochaine échéance'),
                      subtitle: Text(
                        '${maintenance.nextDueMileage?.toStringAsFixed(0) ?? "?"} km'
                        ' ou le ${maintenance.nextDueDate != null ? DateFormat('dd/MM/yyyy').format(maintenance.nextDueDate!) : "?"}',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _infoColumn(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
