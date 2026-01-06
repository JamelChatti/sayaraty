// lib/features/vehicles/presentation/screens/pro_vehicle_list_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_state_notifier.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../application/vehicle_service.dart';

import '../../domain/models/shared_access_model.dart';
import '../../domain/models/vehicule_model.dart'; // Ajoutez cette importation

class ProVehicleListScreen extends ConsumerStatefulWidget {
  const ProVehicleListScreen({super.key});

  @override
  ConsumerState<ProVehicleListScreen> createState() => _ProVehicleListScreenState();
}

class _ProVehicleListScreenState extends ConsumerState<ProVehicleListScreen> {
  bool _isFirstLoad = true;

  @override
  Widget build(BuildContext context) {
    // Récupère l'utilisateur connecté
    final userAsync = ref.watch<AsyncValue<AppUser?>>(authStateNotifierProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Erreur: $err')),
      ),
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/login');
          });
          return const SizedBox();
        }

        // Vérifier si l'utilisateur est un pro
        final isPro = user.role == 'pro' ||
            user.role == 'professional' ||
            user.role == 'mecanic' ||
            user.role == 'mechanic';

        if (!isPro) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/home');
          });
          return const SizedBox();
        }

        // Debug: afficher l'ID utilisateur
        if (_isFirstLoad) {
          print('🔍 Pro user ID: ${user.uid}');
          print('🔍 Pro user role: ${user.role}');
          print('🔍 Pro user email: ${user.email}');
          _isFirstLoad = false;
        }

        // 1. VERSION AVEC LE PROVIDER (recommandée)
        final vehiclesAsync = ref.watch(sharedVehiclesStreamProvider(user.uid));

        // OU 2. VERSION AVEC LE SERVICE DIRECTEMENT (alternative)
        // final sharingService = ref.watch(sharingServiceProvider);
        // final vehiclesAsync = ref.watch(sharedVehiclesFromServiceProvider(user.uid));

        return vehiclesAsync.when(
          loading: () => Scaffold(
            appBar: AppBar(title: const Text('Véhicules clients')),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) {
            print('❌ Erreur chargement véhicules: $err');
            print('❌ Stack trace: $stack');

            // Afficher un bouton pour afficher la requête Firestore manuellement
            return Scaffold(
              appBar: AppBar(title: const Text('Véhicules clients')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur de chargement',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$err',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => ref.invalidate(sharedVehiclesStreamProvider(user.uid)),
                            child: const Text('Réessayer'),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton(
                            onPressed: () => _debugFirestoreQuery(user.uid),
                            child: const Text('Debug Firestore'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          data: (vehicles) {
            // Debug: afficher le nombre de véhicules
            print('🔍 Nombre de véhicules partagés: ${vehicles.length}');
            vehicles.forEach((v) {
              print('   - ${v.brand} ${v.model} (ID: ${v.id})');
              print('     Propriétaire: ${v.ownerId}');
              print('     Partagé avec: ${v.sharedWith.map((a) => a.userId)}');
            });

            return Scaffold(
              appBar: AppBar(
                title: const Text('Véhicules clients'),
                actions: [
                  // Badge pour le nombre de véhicules
                  vehicles.isNotEmpty
                      ? Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: Text(
                        '${vehicles.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                      : const SizedBox(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      ref.invalidate(sharedVehiclesStreamProvider(user.uid));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
              body: vehicles.isEmpty
                  ? _buildEmptyState(context, user.uid)
                  : _buildVehicleList(context, vehicles),
              floatingActionButton: vehicles.isNotEmpty
                  ? FloatingActionButton(
                onPressed: () => _showDebugInfo(context, vehicles, user.uid),
                child: const Icon(Icons.info),
              )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String userId) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.directions_car,
                size: 96,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                'Aucun véhicule partagé',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Vos clients n\'ont pas encore partagé leurs véhicules avec vous.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Instructions pour vos clients :',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInstructionStep(1, 'Ouvrir l\'application Sayaraty'),
                      _buildInstructionStep(2, 'Aller dans "Mes véhicules"'),
                      _buildInstructionStep(3, 'Sélectionner un véhicule'),
                      _buildInstructionStep(4, 'Cliquer sur "Partager"'),
                      _buildInstructionStep(5, 'Chercher votre email professionnel'),
                      _buildInstructionStep(6, 'Sélectionner les permissions et valider'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Votre ID professionnel'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Partagez cet ID avec vos clients :'),
                              const SizedBox(height: 16),
                              Card(
                                color: Colors.blue[50],
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: SelectableText(
                                    userId,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Ou donnez simplement votre adresse email professionnelle :',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ref.read(authStateNotifierProvider).value?.email ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Fermer'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Voir mon ID professionnel'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _debugFirestoreQuery(userId),
                    child: const Text('Vérifier la connexion Firestore'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleList(BuildContext context, List<Vehicle> vehicles) {
    return RefreshIndicator(
      onRefresh: () async {
        final user = ref.read(authStateNotifierProvider).value;
        if (user != null) {
          ref.invalidate(sharedVehiclesStreamProvider(user.uid));
        }
      },
      child: ListView.builder(
        itemCount: vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = vehicles[index];
          return _buildVehicleCard(context, vehicle);
        },
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, Vehicle vehicle) {
    final ownerName = vehicle.sharedWith.firstWhere(
          (access) => access.userId == vehicle.ownerId,
      orElse: () => SharedAccess(
        userId: vehicle.ownerId ,
        email: '',
        displayName: vehicle.ownerName,
        permissions: [],
        sharedAt: DateTime.now(),
      ),
    ).displayName;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: InkWell(
        onTap: () => _navigateToVehicleDetails(context, vehicle),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Photo du véhicule
              _buildVehicleImage(vehicle),
              const SizedBox(width: 16),
              // Informations du véhicule
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.brand} ${vehicle.model}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (vehicle.plateNumber != null)
                      Text(
                        vehicle.plateNumber!,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (ownerName != null)
                      Text(
                        'Client: $ownerName',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(height: 4),
                      Text(
                        'Année: ${vehicle.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleImage(Vehicle vehicle) {
    if (vehicle.mainPhotoUrl != null && vehicle.mainPhotoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: vehicle.mainPhotoUrl!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 80,
            height: 80,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            width: 80,
            height: 80,
            color: Colors.grey[200],
            child: const Icon(Icons.directions_car, color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.directions_car,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _navigateToVehicleDetails(BuildContext context, Vehicle vehicle) {
    context.push('/maintenance', extra: {
      'ownerId': vehicle.ownerId,
      'vehicleId': vehicle.id,
      'vehicleName': '${vehicle.brand} ${vehicle.model}',
      'plateNumber': vehicle.plateNumber,
    });
  }

  void _debugFirestoreQuery(String userId) async {
    try {
      print('🔍 Début du debug Firestore...');
      print('🔍 User ID: $userId');

      // Test de la requête Firestore directement
      final snapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('sharedWithUserIds', arrayContains: userId)
          .limit(5)
          .get();

      print('🔍 Nombre de documents trouvés: ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        print('   📄 Document ID: ${doc.id}');
        print('   📄 Données: ${doc.data()}');
        print('   ---');
      }

      if (snapshot.docs.isEmpty) {
        print('⚠️ Aucun véhicule trouvé avec sharedWithUserIds contenant $userId');
        print('💡 Vérifiez que:');
        print('   1. Les clients ont bien partagé des véhicules avec ce pro');
        print('   2. Le champ sharedWithUserIds existe dans les documents véhicules');
        print('   3. L\'ID utilisateur est correct: $userId');
      }

      // Afficher une alerte avec les résultats
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Debug Firestore'),
          content: SingleChildScrollView(
            child: Text(
              'Résultats de la requête:\n\n'
                  'ID utilisateur: $userId\n'
                  'Véhicules trouvés: ${snapshot.docs.length}\n\n'
                  'Documents:\n${snapshot.docs.map((d) => '- ${d.id}: ${d.data()}').join('\n')}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ Erreur debug Firestore: $e');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erreur Debug'),
          content: Text('Erreur lors de la requête Firestore: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    }
  }

  void _showDebugInfo(BuildContext context, List<Vehicle> vehicles, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations de debug'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Informations utilisateur:'),
              Text('ID: $userId', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Véhicules partagés:'),
              ...vehicles.take(5).map((v) => Text(
                '  - ${v.brand} ${v.model} (ID: ${v.id})',
                style: const TextStyle(fontSize: 12),
              )),
              if (vehicles.length > 5)
                Text('  ... et ${vehicles.length - 5} autres'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}