// lib/features/vehicles/presentation/screens/vehicle_list_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_state_notifier.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../../core/security/password_confirm_dialog.dart';
import '../../application/share_invitation_service.dart';
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
    ref.listenManual(
      pendingShareInvitationsProvider(widget.userId),
      (previous, next) {
        final invites = next.asData?.value;
        if (invites == null || invites.isEmpty) return;
        final prevIds =
            previous?.asData?.value.map((e) => e.id).toSet() ?? {};
        // Première charge : mémoriser sans spammer; ensuite notifier les nouvelles.
        if (previous == null) {
          ShareInvitationNotifier.instance.markSeen(invites.map((e) => e.id));
          return;
        }
        final fresh = invites.where((i) => !prevIds.contains(i.id)).toList();
        if (fresh.isNotEmpty) {
          ShareInvitationNotifier.instance.notifyNewInvitations(fresh);
        }
      },
      fireImmediately: true,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = ref.read(authStateNotifierProvider).asData?.value;
      if (auth == null) return;
      await ref.read(shareInvitationServiceProvider).claimPendingInvitations(
            userId: auth.uid,
            email: auth.email,
          );
    });
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
    final pendingInvites =
        ref.watch(pendingShareInvitationsProvider(widget.userId)).asData?.value ??
            const [];

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
                icon: Badge(
                  isLabelVisible: pendingInvites.isNotEmpty,
                  label: Text('${pendingInvites.length}'),
                  child: const Icon(Icons.mail_outline),
                ),
                tooltip: 'Invitations de partage',
                onPressed: () => context.push('/vehicles/invitations'),
              ),
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
                ),
                onPressed: () => context.push('/vehicles/shared'),
              ),
            ],
          ),

          body: vehicles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (pendingInvites.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _PendingInvitesBanner(
                            count: pendingInvites.length,
                            onTap: () =>
                                context.push('/vehicles/invitations'),
                          ),
                        ),
                      ],
                      const Icon(Icons.directions_car, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucun véhicule',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ajoutez votre premier véhicule pour commencer à suivre son entretien.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount:
                      vehicles.length + (pendingInvites.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (pendingInvites.isNotEmpty && index == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                        child: _PendingInvitesBanner(
                          count: pendingInvites.length,
                          onTap: () => context.push('/vehicles/invitations'),
                        ),
                      );
                    }

                    final vehicle = vehicles[
                        pendingInvites.isNotEmpty ? index - 1 : index];
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

class _PendingInvitesBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _PendingInvitesBanner({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.teal.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.mail, color: Colors.teal.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  count == 1
                      ? '1 invitation de partage à accepter'
                      : '$count invitations de partage à accepter',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade900,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.teal.shade700),
            ],
          ),
        ),
      ),
    );
  }
}
