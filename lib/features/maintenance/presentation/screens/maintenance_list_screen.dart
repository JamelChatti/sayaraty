// lib/features/maintenance/presentation/screens/maintenance_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/security/password_confirm_dialog.dart';
import '../../../auth/application/auth_state_notifier.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../settings/application/currency_provider.dart';
import '../../../settings/domain/app_settings.dart';
import '../../../vehicules/application/vehicle_expiry_notification_service.dart';
import '../../../vehicules/application/vehicle_service.dart';
import '../../application/maintenance_service.dart';
import '../../domain/maintenance_type_ui.dart';
import '../../domain/models/maintenance_model.dart';
import '../widgets/maintenance_due_banner.dart';
import 'maintenance_detail_sceen.dart';
import '../../../../app/app_theme.dart';

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
    final currency = ref.watch(currencyProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
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

        final isProfessional =
            user.role == 'pro' || user.userType == 'professional';
        final userIdForQuery = _getUserIdForQuery(user, ownerId);

        final maintenancesAsync = ref.watch(
          isProfessional
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
            error: (err, _) {
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
                        isProfessional
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

              final canDismissDue = _canDismissDueReminder(user, ownerId) &&
                  maintenances.any(
                    (m) => m.isDueOverdue || m.isDueWithinDays(30),
                  );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MaintenanceDueBanner(
                    maintenances: maintenances,
                    canDismiss: canDismissDue,
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: maintenances.length,
                      itemBuilder: (context, index) {
                        final maintenance = maintenances[index];
                        return _MaintenanceListItem(
                          maintenance: maintenance,
                          currency: currency,
                          canEdit: _canEditMaintenance(
                            user,
                            maintenance,
                            ownerId,
                          ),
                          canDismissDue: canDismissDue &&
                              maintenance.nextDueDate != null &&
                              (maintenance.isDueOverdue ||
                                  maintenance.isDueWithinDays(30)),
                          onDismissDue: () => _dismissDueReminder(
                            context,
                            ref,
                            maintenance,
                          ),
                          vehicleName: vehicleName,
                          onEdit: () => context.push(
                            '/maintenance/edit/${maintenance.id}',
                            extra: {
                              'maintenance': maintenance,
                              'vehicleName': vehicleName,
                            },
                          ),
                          onDelete: () =>
                              _deleteMaintenance(context, ref, maintenance.id),
                        );
                      },
                    ),
                  ),
                ],
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
    if ((user.role == 'pro' || user.userType == 'professional') &&
        providedClientId != null) {
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
    } catch (_) {
      return false;
    }
  }

  // Propriétaire du véhicule : peut masquer les rappels d'échéance
  bool _canDismissDueReminder(AppUser user, String? ownerId) {
    if (user.role == 'pro' || user.userType == 'professional') {
      return false;
    }
    if (ownerId != null && ownerId != user.uid) {
      return false;
    }
    return true;
  }

  Future<void> _dismissDueReminder(
    BuildContext context,
    WidgetRef ref,
    Maintenance maintenance,
  ) async {
    final confirmed = await confirmWithPassword(
      context,
      title: 'Maintenance effectuée ?',
      message:
          'Confirmer que « ${maintenance.title} » a été effectuée ?\n'
          'Le rappel d\'échéance ne sera plus affiché.\n'
          'Entrez votre mot de passe pour confirmer.',
      confirmLabel: 'Confirmer',
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(maintenanceServiceProvider)
          .clearDueReminder(maintenance.id);
      final vehicles =
          ref.read(vehiclesStreamProvider(maintenance.userId)).asData?.value;
      if (vehicles != null) {
        await ref
            .read(vehicleExpiryNotificationServiceProvider)
            .syncVehicles(vehicles, force: true);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rappel d\'échéance supprimé')),
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

  // ✅ CORRIGÉ : Vérifier les permissions d'édition/suppression
  bool _canEditMaintenance(
    AppUser user,
    Maintenance maintenance,
    String? ownerId,
  ) {
    // Un propriétaire peut éditer ses propres maintenances
    if (user.role != 'pro' && user.userType != 'professional') {
      return maintenance.userId == user.uid;
    }

    // Un professionnel ne peut pas éditer les maintenances
    return false;
  }

  // ✅ CORRIGÉ : Méthode de suppression
  Future<void> _deleteMaintenance(
    BuildContext context,
    WidgetRef ref,
    String maintenanceId,
  ) async {
    final confirm = await confirmWithPassword(
      context,
      title: 'Supprimer ?',
      message:
          'Êtes-vous sûr de vouloir supprimer cette intervention ?\n'
          'Entrez votre mot de passe pour confirmer.',
      confirmLabel: 'Supprimer',
      isDestructive: true,
    );

    if (confirm == true) {
      try {
        await ref
            .read(maintenanceServiceProvider)
            .deleteMaintenance(maintenanceId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Intervention supprimée')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
        }
      }
    }
  }
}

class _MaintenanceListItem extends StatelessWidget {
  final Maintenance maintenance;
  final CurrencyEnum currency;
  final bool canEdit;
  final bool canDismissDue;
  final VoidCallback onDismissDue;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String vehicleName;

  const _MaintenanceListItem({
    required this.maintenance,
    required this.currency,
    required this.canEdit,
    this.canDismissDue = false,
    required this.onDismissDue,
    required this.onEdit,
    required this.onDelete,
    required this.vehicleName,
  });

  @override
  Widget build(BuildContext context) {
    final formattedCost = formatCurrency(maintenance.cost, currency);
    final statusColor = _getStatusColor(maintenance.status);
    final typeColor = _getTypeColor(maintenance.type);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getTypeIcon(maintenance.type),
            color: typeColor,
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
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _getStatusLabel(maintenance.status),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatDate(maintenance.date)} • ${maintenance.mileage.toStringAsFixed(0)} km',
            ),
            if (maintenance.garageName != null &&
                maintenance.garageName!.isNotEmpty)
              Text(maintenance.garageName!),
            Text(
              formattedCost,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (maintenance.items.isNotEmpty)
              Text('${maintenance.items.length} élément(s)'),
            if (maintenance.nextDueDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _DueChip(maintenance: maintenance),
                  ),
                  if (canDismissDue)
                    TextButton.icon(
                      onPressed: onDismissDue,
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Effectuée'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
        trailing: (canEdit || canDismissDue)
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'details') {
                    _openDetails(context);
                  } else if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  } else if (value == 'dismiss_due') {
                    onDismissDue();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: ListTile(
                      leading: Icon(Icons.visibility, color: Colors.blue),
                      title: Text('Détails'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (canDismissDue)
                    const PopupMenuItem(
                      value: 'dismiss_due',
                      child: ListTile(
                        leading: Icon(
                          Icons.notifications_off,
                          color: Colors.green,
                        ),
                        title: Text('Masquer le rappel'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  if (canEdit) ...[
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit, color: Colors.orange),
                        title: Text('Modifier'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Supprimer'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ],
              )
            : const Icon(Icons.chevron_right),
        onTap: () => _openDetails(context),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaintenanceDetailScreen(
          maintenance: maintenance,
          vehicleName: vehicleName,
        ),
      ),
    );
  }

  Color _getTypeColor(MaintenanceType type) => MaintenanceTypeUi.color(type);

  IconData _getTypeIcon(MaintenanceType type) => MaintenanceTypeUi.icon(type);

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

class _DueChip extends StatelessWidget {
  final Maintenance maintenance;

  const _DueChip({required this.maintenance});

  @override
  Widget build(BuildContext context) {
    final due = maintenance.nextDueDate!;
    final overdue = maintenance.isDueOverdue;
    final soon = maintenance.isDueWithinDays(30);
    final color = overdue
        ? AppTheme.overdue
        : soon
        ? AppTheme.dueSoon
        : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        overdue
            ? 'Échéance dépassée : ${_formatDate(due)}'
            : 'Échéance : ${_formatDate(due)}',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
