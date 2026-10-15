// lib/features/vehicles/presentation/screens/vehicle_list_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_state_notifier.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../../core/security/password_confirm_dialog.dart';
import '../../application/vehicle_expiry_notification_service.dart';
import '../../application/vehicle_providers.dart';
import '../../application/vehicle_service.dart' hide vehiclesStreamProvider;
import 'full_screen_image.dart';

class VehicleListScreen extends ConsumerWidget {
  const VehicleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch<AsyncValue<AppUser?>>(
      authStateNotifierProvider,
    );
    return userState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text('Erreur: $err'))),
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

class _VehicleListBody extends ConsumerStatefulWidget {
  final String userId;

  const _VehicleListBody({required this.userId});

  @override
  ConsumerState<_VehicleListBody> createState() => _VehicleListBodyState();
}

class _VehicleListBodyState extends ConsumerState<_VehicleListBody> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(
      vehiclesStreamProvider(widget.userId),
      (previous, next) {
        final vehicles = next.asData?.value;
        if (vehicles == null) return;
        ref
            .read(vehicleExpiryNotificationServiceProvider)
            .syncVehicles(vehicles, force: previous != null);
      },
      fireImmediately: true,
    );
  }

  Future<void> _showDeleteDialog(String vehicleId) async {
    final confirm = await confirmWithPassword(
      context,
      title: 'Supprimer ce véhicule ?',
      message:
          'Toutes les interventions liées seront aussi supprimées.\n'
          'Entrez votre mot de passe pour confirmer.',
      confirmLabel: 'Supprimer',
      isDestructive: true,
    );

    if (confirm == true) {
      await ref.read(vehicleServiceProvider).deleteVehicle(vehicleId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Véhicule supprimé')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesStreamProvider(widget.userId));

    return vehiclesAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text('Erreur: $err'))),
      data: (vehicles) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Image.asset(
                  'assets/images/logo_sayaraty.png',
                  height: 36,
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Sayaraty',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => context.push('/settings'),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.blue),
                onPressed: () => context.push('/vehicles/add'),
              ),
              IconButton(
                icon: const Icon(
                  Icons.group,
                  color: Colors.green,
                ), // Icône pour la famille/entreprise
                onPressed: () =>
                    context.push('/vehicles/share'), // Route à définir
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
                    final subtitle =
                        vehicle.plateNumber ?? 'Immatriculation inconnue';

                    return Dismissible(
                      key: Key(vehicle.id),
                      background: Container(
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) => confirmWithPassword(
                        context,
                        title: 'Supprimer ce véhicule ?',
                        message:
                            'Toutes les interventions liées seront aussi '
                            'supprimées.\nEntrez votre mot de passe pour confirmer.',
                        confirmLabel: 'Supprimer',
                        isDestructive: true,
                      ),
                      onDismissed: (_) async {
                        await ref
                            .read(vehicleServiceProvider)
                            .deleteVehicle(vehicle.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Véhicule supprimé')),
                          );
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(subtitle),
                          leading: GestureDetector(
                            onTap: () {
                              if (vehicle.mainPhotoUrl == null) return;

                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FullScreenImage(
                                    imageUrl: vehicle.mainPhotoUrl!,
                                  ),
                                ),
                              );
                            },
                            child: Hero(
                              tag: vehicle.id,
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.grey[200],
                                child: vehicle.mainPhotoUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: vehicle.mainPhotoUrl!,
                                        fit: BoxFit.cover,
                                        width: 48,
                                        height: 48,
                                        placeholder: (context, url) =>
                                            const CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.grey,
                                                  ),
                                              strokeWidth: 2,
                                            ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(
                                              Icons.directions_car,
                                              color: Colors.grey,
                                            ),
                                      )
                                    : const Icon(
                                        Icons.directions_car,
                                        color: Colors.grey,
                                      ),
                              ),
                            ),
                          ),
                          onTap: () => context.push(
                            '/maintenance',
                            extra: {
                              'ownerId': vehicle.ownerId,
                              'vehicleId': vehicle.id,
                              'vehicleName': title,
                            },
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                context.push('/vehicles/edit/${vehicle.id}');
                              } else if (value == 'delete') {
                                _showDeleteDialog(vehicle.id);
                              } else if (value == 'details') {
                                context.push(
                                  '/vehicles/detail/${vehicle.id}',
                                  extra: vehicle,
                                );
                              } else if (value == 'share') {
                                context.push('/vehicles/share', extra: vehicle);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Modifier',
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'details',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 20,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Détails',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'share',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.share,
                                      size: 20,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Partager',
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Supprimer',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
