// lib/features/vehicles/presentation/screens/vehicle_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/application/auth_state_notifier.dart';
import '../../application/vehicle_providers.dart';
import '../../application/vehicle_service.dart' hide vehiclesStreamProvider;
import '../../domain/models/vehicule_model.dart';


class VehicleListScreen extends ConsumerWidget {
  const VehicleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(authStateProvider);
    return userState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Erreur: $err'))),
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.push('/login');
          });
          return const SizedBox();
        }

        return _VehicleListBody(userId: user.uid);
      },
    );
  }
}

class _VehicleListBody extends ConsumerWidget {
  final String userId;

  const _VehicleListBody({required this.userId});

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref, String vehicleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce véhicule ?'),
        content: const Text('Toutes les interventions liées seront aussi supprimées.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(vehicleServiceProvider).deleteVehicle(vehicleId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Véhicule supprimé')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesStreamProvider(userId));

    return vehiclesAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Erreur: $err'))),
      data: (vehicles) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  color: const Color(0xFFF5F7FB),
                  child: Image.asset(
                    'assets/images/logo_sayaraty.png',
                    height: 65,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Sayaraty'),
              ],
            ),
            actions: [IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push('/settings'),
            ),
              IconButton(
                icon: const Icon(Icons.add_circle,color: Colors.blue,),
                onPressed: () => context.push('/vehicles/add'),
              ),
            ],
          ),
          body: vehicles.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.directions_car, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucun véhicule',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Ajoutez votre premier véhicule pour commencer à suivre son entretien.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
              : ListView.builder(
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              final title = '${vehicle.brand} ${vehicle.model}';
              final subtitle = vehicle.plateNumber ?? 'Immatriculation inconnue';

              return Dismissible(
                key: Key(vehicle.id),
                background: Container(color: Colors.red, child: const Icon(Icons.delete, color: Colors.white)),
                onDismissed: (_) async {
                  await ref.read(vehicleServiceProvider).deleteVehicle(vehicle.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Véhicule supprimé')),
                    );
                  }
                },
                child:ListTile(
                  title: Text(title),
                  subtitle: Text(subtitle),
                  leading: Icon(_getVehicleIcon(vehicle)),
                  onTap: () => context.push('/maintenance', extra: {
                    'vehicleId': vehicle.id,
                    'vehicleName': title,
                  }),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        context.push('/vehicles/edit/${vehicle.id}');
                      } else if (value == 'delete') {
                        _showDeleteDialog(context, ref, vehicle.id);
                      } else if (value == 'details') {
                        // 👇 Naviguez vers les détails
                        context.push('/vehicles/detail/${vehicle.id}', extra: vehicle);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                      const PopupMenuItem(value: 'details', child: Text('Voir les détails')), // ✅ Ajouté
                      const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  IconData _getVehicleIcon(Vehicle vehicle) {
    // Vous pouvez adapter cette logique selon le rôle ou le type de véhicule plus tard
    return Icons.directions_car;
  }
}