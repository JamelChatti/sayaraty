// lib/features/vehicles/presentation/screens/pro_vehicle_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_state_notifier.dart';
import '../../application/vehicle_service.dart';

class ProVehicleListScreen extends ConsumerWidget {
  const ProVehicleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupère l'utilisateur connecté
    final userAsync = ref.watch(authStateProvider);
    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Erreur: $err'))),
      data: (user) {
        if (user == null || user.role != 'pro') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/login');
          });
          return const SizedBox();
        }

        // Charge les véhicules partagés avec ce pro
        final vehiclesAsync = ref.watch(sharedVehiclesStreamProvider(user.uid));

        return vehiclesAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (err, _) => Scaffold(body: Center(child: Text('Erreur: $err'))),
          data: (vehicles) {
            return Scaffold(
              appBar: AppBar(title: const Text('Véhicules clients'),
                actions: [IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => context.push('/settings'),
                ),
                ],
              ),
              body: vehicles.isEmpty
                  ? const Center(
                child: Text('Aucun véhicule partagé avec vous'),
              )
                  : ListView.builder(
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  final title = '${vehicle.brand} ${vehicle.model}';
                  final subtitle = vehicle.plateNumber ?? 'Immatriculation inconnue';

                  return ListTile(
                    title: Text(title),
                    subtitle: Text(subtitle),
                    leading: const Icon(Icons.directions_car),
                    onTap: () => context.push('/maintenance', extra: {
                      'vehicleId': vehicle.id,
                      'vehicleName': title,
                    }),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}