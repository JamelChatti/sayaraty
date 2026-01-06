// lib/features/maintenance/presentation/screens/maintenance_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/application/auth_state_notifier.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../settings/application/settings_service.dart';
import '../../../settings/domain/app_settings.dart';
import '../../application/maintenance_service.dart';
import '../../domain/models/maintenance_model.dart';

class MaintenanceListScreen extends ConsumerWidget {
  final String vehicleId;
  final String vehicleName;
  final String? ownerId;
  final String? clientName;

  const MaintenanceListScreen({
    super.key,
    this.ownerId,
    this.clientName,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateNotifierProvider);
    final currency = ref.watch(appSettingsProvider).asData?.value.currency ?? CurrencyEnum.eur;

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Erreur d\'authentification : $err')),
      ),
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/login');
          });
          return const SizedBox();
        }

        print('👤 Utilisateur connecté:');
        print('   - ID: ${user.uid}');
        print('   - Rôle: ${user.role}');
        print('   - UserType: ${user.userType}');
        print('   - Client ID fourni: $ownerId');
        print('   - Vehicle ID: $vehicleId');

        // ✅ CORRIGÉ : Utiliser la méthode correcte pour déterminer l'ID
        final userIdForQuery = _getUserIdForQuery(user, ownerId);
        print('🔍 ID utilisateur pour la requête: $userIdForQuery');

        // ✅ CORRIGÉ : Utiliser le provider du service
        final maintenancesAsync = ref.watch(
          (user.role == 'pro' || user.userType == 'professional')
              ? professionalMaintenancesStreamProvider((
              professionalId: user.uid,
              vehicleId: vehicleId,
              clientId: userIdForQuery!,
          ))
              : maintenancesStreamProvider((
              userId: userIdForQuery!,
              vehicleId: vehicleId,
          )),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(
              clientName != null
                  ? '$vehicleName (${clientName!})'
                  : 'Historique - $vehicleName',
            ),
            actions: [
              // Bouton d'ajout (visible seulement si l'utilisateur a la permission)
              FutureBuilder<bool>(
                future: _checkAddPermission(ref, user, vehicleId),
                builder: (context, snapshot) {
                  final canAdd = snapshot.data ?? false;
                  if (canAdd) {
                    return IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => context.push(
                        '/maintenance/add',
                        extra: {
                          'ownerId': userIdForQuery,
                          'vehicleId': vehicleId,
                          'vehicleName': vehicleName,
                        },
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
          ),
          body: maintenancesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stackTrace) {
              print('❌ Erreur de chargement: $err');
              print('Stack trace: $stackTrace');

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Erreur de chargement',
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Détails: $err',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(
                        (user.role == 'pro' || user.userType == 'professional')
                            ? professionalMaintenancesStreamProvider((
                            professionalId: user.uid,
                            vehicleId: vehicleId,
                            clientId: userIdForQuery,
                        ))
                            : maintenancesStreamProvider((
                            userId: userIdForQuery,
                            vehicleId: vehicleId,
                        )),
                      ),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            },
            data: (maintenances) {
              print('✅ Nombre de maintenances chargées: ${maintenances.length}');

              if (maintenances.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        ownerId != null
                            ? 'Ce véhicule n\'a pas encore d\'historique de maintenance'
                            : 'Aucune intervention enregistrée',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          ownerId != null
                              ? 'Le propriétaire n\'a pas encore ajouté de maintenance.'
                              : 'Ajoutez votre première intervention pour commencer l\'historique.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: maintenances.length,
                itemBuilder: (context, index) {
                  final maintenance = maintenances[index];
                  return _MaintenanceListItem(
                    maintenance: maintenance,
                    currency: currency,
                    canEdit: _canEditMaintenance(user, maintenance, ownerId),
                    onEdit: () => context.push('/maintenance/edit/${maintenance.id}'),
                    onDelete: () => _deleteMaintenance(context, ref, maintenance.id),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  // ✅ CORRIGÉ : Méthode unique pour déterminer l'ID utilisateur
  String? _getUserIdForQuery(AppUser user, String? providedClientId) {
    // Pour un professionnel, utiliser l'ID du client fourni
    if ((user.role == 'pro' || user.userType == 'professional') && providedClientId != null) {
      return providedClientId;
    }
    // Pour un propriétaire, utiliser son propre ID
    return user.uid;
  }

  // ✅ CORRIGÉ : Vérifier les permissions d'ajout
  Future<bool> _checkAddPermission(
      WidgetRef ref,
      AppUser user,
      String vehicleId,
      ) async {
    // Si l'utilisateur est propriétaire
    if (user.role != 'pro' && user.userType != 'professional') {
      return true;
    }

    // Si c'est un professionnel, vérifier s'il a la permission d'ajouter
    try {
      final vehicleDoc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      final vehicleData = vehicleDoc.data();
      if (vehicleData == null) return false;

      final sharedList = List<Map<String, dynamic>>.from(
        vehicleData['sharedWith'] ?? [],
      );

      final userAccess = sharedList.firstWhere(
            (access) => access['userId'] == user.uid,
        orElse: () => {},
      );

      final permissions = List<String>.from(userAccess['permissions'] ?? []);
      return permissions.contains('maintenance_add');
    } catch (e) {
      print('Erreur lors de la vérification des permissions: $e');
      return false;
    }
  }

  // ✅ CORRIGÉ : Vérifier les permissions d'édition/suppression
  bool _canEditMaintenance(AppUser user, Maintenance maintenance, String? ownerId) {
    // Un propriétaire peut éditer ses propres maintenances
    if (user.role != 'pro' && user.userType != 'professional') {
      return maintenance.userId == user.uid;
    }

    // Un professionnel ne peut pas éditer les maintenances
    return false;
  }

  // ✅ CORRIGÉ : Méthode de suppression
  Future<void> _deleteMaintenance(BuildContext context, WidgetRef ref, String maintenanceId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette intervention ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(maintenanceServiceProvider).deleteMaintenance(maintenanceId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Intervention supprimée')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e')),
          );
        }
      }
    }
  }
}

class _MaintenanceListItem extends StatelessWidget {
  final Maintenance maintenance;
  final CurrencyEnum currency;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MaintenanceListItem({
    required this.maintenance,
    required this.currency,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final formattedCost = formatCurrency(maintenance.cost, currency);
    final statusColor = _getStatusColor(maintenance.status);

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
            Expanded(
              child: Text(
                maintenance.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
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
            Text(
              '📆 ${_formatDate(maintenance.date)} • 🛞 ${maintenance.mileage.toStringAsFixed(0)} km',
            ),
            if (maintenance.garageName != null && maintenance.garageName!.isNotEmpty)
              Text('📍 ${maintenance.garageName!}'),
            Text('💰 $formattedCost'),
            if (maintenance.items.isNotEmpty)
              Text('🔧 ${maintenance.items.length} élément(s)'),
          ],
        ),
        trailing: canEdit
            ? PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        )
            : null,
        onTap: () {
          // Optionnel : Afficher plus de détails
          // context.push('/maintenance/detail/${maintenance.id}');
        },
      ),
    );
  }

  Color _getTypeColor(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.oilChange:
        return Colors.deepPurple;
      case MaintenanceType.brakes:
        return Colors.orange;
      case MaintenanceType.tires:
        return Colors.brown;
      case MaintenanceType.battery:
        return Colors.red;
      case MaintenanceType.timingBelt:
        return Colors.pink;
      case MaintenanceType.technicalInspection:
        return Colors.blue;
      case MaintenanceType.repair:
        return Colors.redAccent;
      case MaintenanceType.other:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.oilChange:
        return Icons.local_gas_station;
      case MaintenanceType.brakes:
        return Icons.directions_car_filled;
      case MaintenanceType.tires:
        return Icons.tire_repair;
      case MaintenanceType.battery:
        return Icons.battery_full;
      case MaintenanceType.timingBelt:
        return Icons.settings;
      case MaintenanceType.technicalInspection:
        return Icons.checklist;
      case MaintenanceType.repair:
        return Icons.build;
      case MaintenanceType.other:
        return Icons.more_horiz;
    }
  }

  Color _getStatusColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.completed:
        return Colors.green;
      case MaintenanceStatus.planned:
        return Colors.blue;
      case MaintenanceStatus.canceled:
        return Colors.red;
    }
  }

  String _getStatusLabel(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.completed:
        return 'Terminée';
      case MaintenanceStatus.planned:
        return 'Planifiée';
      case MaintenanceStatus.canceled:
        return 'Annulée';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}