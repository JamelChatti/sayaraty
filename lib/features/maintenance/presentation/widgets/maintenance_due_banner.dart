import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/security/password_confirm_dialog.dart';
import '../../application/maintenance_service.dart';
import '../../domain/models/maintenance_model.dart';

/// Bandeau récapitulatif des prochaines échéances pour un véhicule.
class MaintenanceDueBanner extends ConsumerWidget {
  final List<Maintenance> maintenances;
  final bool canDismiss;

  const MaintenanceDueBanner({
    super.key,
    required this.maintenances,
    this.canDismiss = false,
  });

  static List<Maintenance> _overdue(List<Maintenance> maintenances) =>
      maintenances.where((m) => m.isDueOverdue).toList();

  static List<Maintenance> _soon(List<Maintenance> maintenances) =>
      maintenances
          .where((m) => m.isDueWithinDays(30) && !m.isDueOverdue)
          .toList()
        ..sort(
          (a, b) => (a.nextDueDate ?? DateTime(2100)).compareTo(
            b.nextDueDate ?? DateTime(2100),
          ),
        );

  Future<void> _confirmAndDismiss(
    BuildContext context,
    WidgetRef ref,
    List<Maintenance> dueMaintenances,
  ) async {
    final count = dueMaintenances.length;
    final confirmed = await confirmWithPassword(
      context,
      title: 'Maintenance effectuée ?',
      message: count == 1
          ? 'Confirmer que « ${dueMaintenances.first.title} » a été effectuée ? '
              'Le rappel d\'échéance ne sera plus affiché.\n'
              'Entrez votre mot de passe pour confirmer.'
          : 'Confirmer que les $count échéances affichées ont été effectuées ? '
              'Les rappels ne seront plus affichés.\n'
              'Entrez votre mot de passe pour confirmer.',
      confirmLabel: 'Confirmer',
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final service = ref.read(maintenanceServiceProvider);
      for (final maintenance in dueMaintenances) {
        await service.clearDueReminder(maintenance.id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count == 1
                  ? 'Rappel d\'échéance supprimé'
                  : '$count rappels d\'échéance supprimés',
            ),
          ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overdue = _overdue(maintenances);
    final soon = _soon(maintenances);
    final dueMaintenances = [...overdue, ...soon];

    if (dueMaintenances.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isOverdue = overdue.isNotEmpty;
    final highlight = isOverdue ? AppTheme.overdue : AppTheme.dueSoon;
    final count = dueMaintenances.length;
    final next = dueMaintenances.first;
    final nextDate = next.nextDueDate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: highlight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isOverdue
                    ? Icons.warning_amber_rounded
                    : Icons.notifications_active_outlined,
                color: highlight,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOverdue
                          ? '$count échéance(s) en retard'
                          : '$count échéance(s) à venir',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: highlight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nextDate != null
                          ? 'Prochaine : ${next.title} — ${DateFormat('dd/MM/yyyy').format(nextDate)}'
                          : next.title,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (canDismiss) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _confirmAndDismiss(context, ref, dueMaintenances),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Marquer comme effectuée'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: highlight,
                          side: BorderSide(color: highlight),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
