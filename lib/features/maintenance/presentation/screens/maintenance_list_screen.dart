// lib/features/maintenance/presentation/screens/maintenance_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/application/auth_state_notifier.dart';
import '../../../settings/application/settings_service.dart';
import '../../../settings/domain/app_settings.dart';
import '../../application/maintenance_service.dart';
import '../../domain/models/maintenance_model.dart';


class MaintenanceListScreen extends ConsumerWidget {
  final String vehicleId;
  final String vehicleName; // ex: "Renault Clio AB-123-CD"


  const MaintenanceListScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final currency = ref.watch(appSettingsProvider).asData?.value?.currency ?? CurrencyEnum.eur;
    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Auth erreur: $err'))),
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/login');
          });
          return const SizedBox();
        }

        // ✅ Maintenant on peut utiliser user.uid en toute sécurité
        final maintenancesAsync = ref.watch(
          maintenancesStreamProvider(
            (userId: user.uid, vehicleId: vehicleId), // ✅ pas "widget.vehicleId"
          ),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text('Historique - $vehicleName'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => context.push('/maintenance/add', extra: {
                  'vehicleId': vehicleId,
                  'vehicleName': vehicleName,
                }),
              ),
            ],
          ),
          body: maintenancesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Erreur: $err')),
            data: (maintenances) {
              if (maintenances.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucune intervention',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Ajoutez votre première vidange, réparation ou contrôle technique.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: maintenances.length,
                itemBuilder: (context, index) {
                  final m = maintenances[index];
                  return _MaintenanceListItem(
                    maintenance: m,
                    currency: currency,
                    onEdit: () => context.push('/maintenance/edit/${m.id}'),
                    onDelete: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Supprimer ?'),
                          content: const Text('Êtes-vous sûr de vouloir supprimer cette intervention ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Supprimer'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(maintenanceServiceProvider).deleteMaintenance(m.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Intervention supprimée')),
                          );
                        }
                      }
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _MaintenanceListItem extends StatelessWidget {
  final Maintenance maintenance;
  final CurrencyEnum currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MaintenanceListItem({
    required this.maintenance,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final formattedCost = formatCurrency(maintenance.cost, currency);
    final statusColor = maintenance.status == MaintenanceStatus.completed
        ? Colors.green
        : maintenance.status == MaintenanceStatus.planned
        ? Colors.blue
        : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getTypeColor(maintenance.type),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getTypeIcon(maintenance.type),
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(maintenance.title, style: const TextStyle(fontWeight: FontWeight.bold))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getStatusLabel(maintenance.status),
                style: TextStyle(color: statusColor, fontSize: 12),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📆 ${_formatDate(maintenance.date)} • 🛞 ${maintenance.mileage.toStringAsFixed(0)} km'),
            if (maintenance.garageName != null) Text('📍 ${maintenance.garageName!}'),
            Text('💰 $formattedCost'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Modifier')),
            const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.oilChange: return Colors.deepPurple;
      case MaintenanceType.brakes: return Colors.orange;
      case MaintenanceType.tires: return Colors.brown;
      case MaintenanceType.battery: return Colors.red;
      case MaintenanceType.timingBelt: return Colors.pink;
      case MaintenanceType.technicalInspection: return Colors.blue;
      case MaintenanceType.repair: return Colors.redAccent;
      case MaintenanceType.other: return Colors.grey;
    }
  }

  IconData _getTypeIcon(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.oilChange: return Icons.local_gas_station;
      case MaintenanceType.brakes: return Icons.directions_car_filled;
      case MaintenanceType.tires: return Icons.tire_repair;
      case MaintenanceType.battery: return Icons.battery_full;
      case MaintenanceType.timingBelt: return Icons.settings;
      case MaintenanceType.technicalInspection: return Icons.checklist;
      case MaintenanceType.repair: return Icons.build;
      case MaintenanceType.other: return Icons.more_horiz;
    }
  }

  String _getStatusLabel(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.completed: return 'Terminée';
      case MaintenanceStatus.planned: return 'Planifiée';
      case MaintenanceStatus.canceled: return 'Annulée';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}