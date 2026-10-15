import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../application/vehicle_service.dart';
import '../../domain/models/routine_maintenance.dart';
import '../../domain/models/vehicule_model.dart';
import '../screens/routine_config_screen.dart';

class RoutineStatusSection extends ConsumerWidget {
  final String vehicleId;

  const RoutineStatusSection({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync = ref.watch(vehicleByIdStreamProvider(vehicleId));

    return vehicleAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (vehicle) {
        if (vehicle == null) return const SizedBox.shrink();
        return _RoutineStatusBody(vehicle: vehicle);
      },
    );
  }
}

class _RoutineStatusBody extends StatelessWidget {
  final Vehicle vehicle;

  const _RoutineStatusBody({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statuses = vehicle.routine.allStatuses(
      currentMileage: vehicle.mileage,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Entretiens de routine',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoutineConfigScreen(vehicle: vehicle),
                  ),
                );
              },
              icon: const Icon(Icons.tune, size: 18),
              label: Text(
                vehicle.routine.hasAnyInterval ? 'Configurer' : 'Définir',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!vehicle.routine.hasAnyInterval)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: const ListTile(
              leading: Icon(Icons.build_circle_outlined),
              title: Text('Aucun intervalle défini'),
              subtitle: Text(
                'Vidange, pneus, chaîne/courroie et batterie',
              ),
            ),
          )
        else
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: statuses.map((s) {
                final color = s.isOverdue
                    ? AppTheme.overdue
                    : s.isDueSoon
                        ? AppTheme.dueSoon
                        : Colors.grey;
                return ListTile(
                  leading: Icon(
                    s.isOverdue
                        ? Icons.warning_amber
                        : s.isDueSoon
                            ? Icons.notifications_active
                            : Icons.check_circle_outline,
                    color: color,
                  ),
                  title: Text(s.kind.label),
                  subtitle: Text(s.summary),
                  dense: true,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
