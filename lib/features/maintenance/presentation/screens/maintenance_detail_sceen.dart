import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../settings/application/currency_provider.dart';
import '../../application/maintenance_service.dart';
import '../../domain/models/maintenance_model.dart';
import '../widgets/maintenance_attachment_section.dart';

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
    final liveAsync =
        ref.watch(maintenanceByIdStreamProvider(maintenance.id));
    final live = liveAsync.asData?.value ?? maintenance;

    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);
    final garageName = live.garageName?.trim();
    final garageContact = live.garageContact?.trim();
    final description = live.description?.trim();
    final hasAdditionalInfo =
        (garageName != null && garageName.isNotEmpty) ||
        (description != null && description.isNotEmpty) ||
        live.nextDueMileage != null ||
        live.nextDueDate != null;

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
                    live.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatCurrency(live.cost, currency),
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
                        DateFormat('dd/MM/yyyy').format(live.date),
                      ),
                      _infoColumn(
                        Icons.speed,
                        'Kilométrage',
                        '${live.mileage.toStringAsFixed(0)} km',
                      ),
                    ],
                  ),
                  if (live.fuelLiters > 0) ...[
                    const SizedBox(height: 12),
                    Chip(
                      avatar: Icon(
                        live.effectiveFullTank
                            ? Icons.check_circle
                            : Icons.water_drop_outlined,
                        size: 18,
                      ),
                      label: Text(
                        live.effectiveFullTank
                            ? 'Plein complet — ${live.fuelLiters.toStringAsFixed(1)} L'
                            : 'Plein partiel — ${live.fuelLiters.toStringAsFixed(1)} L',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (live.items.isNotEmpty) ...[
            _sectionTitle(theme, 'Éléments d’intervention'),
            const SizedBox(height: 8),
            ...live.items.map((item) {
              final priceTTC = item.priceWithTax;
              final brand = item.brand?.trim();
              final note = item.description.trim();
              final reminderParts = <String>[];
              if (item.nextDueMileage != null) {
                reminderParts.add(
                  'Prochain km : ${item.nextDueMileage!.toStringAsFixed(0)}',
                );
              }
              if (item.nextDueDate != null) {
                reminderParts.add(
                  'Date : ${DateFormat('dd/MM/yyyy').format(item.nextDueDate!)}',
                );
              }
              final lines = <String>[
                '${item.quantity} x ${formatCurrency(item.price, currency)} HT (TVA ${item.taxRate}%)',
                if (brand != null && brand.isNotEmpty) 'Marque : $brand',
                if (note.isNotEmpty) 'Note : $note',
                if (reminderParts.isNotEmpty) reminderParts.join(' · '),
              ];

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text(lines.join('\n')),
                  trailing: Text(
                    formatCurrency(priceTTC, currency),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  isThreeLine: lines.length > 1,
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
                if (live.nextDueMileage != null || live.nextDueDate != null)
                  Container(
                    color:
                        (live.isDueOverdue
                                ? AppTheme.overdue
                                : AppTheme.dueSoon)
                            .withValues(alpha: 0.12),
                    child: ListTile(
                      leading: Icon(
                        Icons.notifications_active,
                        color: live.isDueOverdue
                            ? AppTheme.overdue
                            : AppTheme.dueSoon,
                      ),
                      title: const Text('Prochaine échéance'),
                      subtitle: Text(
                        '${live.nextDueMileage?.toStringAsFixed(0) ?? "?"} km'
                        ' ou le ${live.nextDueDate != null ? DateFormat('dd/MM/yyyy').format(live.nextDueDate!) : "?"}',
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          MaintenanceAttachmentSection(maintenanceId: live.id),
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
