// // lib/features/vehicles/presentation/screens/share_vehicle_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:go_router/go_router.dart';
//
//
// import '../../domain/models/shared_access_model.dart';
// import '../../application/sharing_service.dart';
// import '../../domain/models/vehicule_model.dart';
//
// class ShareVehicleScreen extends ConsumerStatefulWidget {
//   final Vehicle vehicle;
//
//   const ShareVehicleScreen({super.key, required this.vehicle});
//
//   @override
//   ConsumerState<ShareVehicleScreen> createState() => _ShareVehicleScreenState();
// }
//
// class _ShareVehicleScreenState extends ConsumerState<ShareVehicleScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   late TextEditingController _searchController;
//   String _searchQuery = '';
//
//   // Constantes pour les permissions
//   static const List<String> readPermissions = ['view'];
//   static const List<String> writePermissions = ['view', 'edit'];
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _searchController = TextEditingController();
//     _searchController.addListener(() {
//       setState(() {
//         _searchQuery = _searchController.text.toLowerCase();
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Partager ${widget.vehicle.brand} ${widget.vehicle.model}'),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(icon: Icon(Icons.person_add), text: 'Inviter'),
//             Tab(icon: Icon(Icons.group), text: 'Déjà partagé'),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           // Premier onglet: Liste des utilisateurs avec recherche
//           _buildUsersListTab(context, currentUser),
//
//           // Deuxième onglet: Utilisateurs déjà partagés
//           _buildSharedWithTab(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildUsersListTab(BuildContext context, User? currentUser) {
//     return Column(
//       children: [
//         // Barre de recherche
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: TextField(
//             controller: _searchController,
//             decoration: InputDecoration(
//               labelText: 'Rechercher par nom ou email',
//               prefixIcon: const Icon(Icons.search),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               filled: true,
//               fillColor: Colors.grey[50],
//             ),
//           ),
//         ),
//
//         // Liste des utilisateurs
//         Expanded(
//           child: StreamBuilder<QuerySnapshot>(
//             stream: FirebaseFirestore.instance
//                 .collection('users')
//                 .where('email', isNotEqualTo: currentUser?.email)
//                 .snapshots(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }
//
//               if (snapshot.hasError) {
//                 return Center(child: Text('Erreur: ${snapshot.error}'));
//               }
//
//               if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                 return const Center(
//                   child: Text('Aucun utilisateur trouvé'),
//                 );
//               }
//
//               final users = snapshot.data!.docs;
//
//               // Filtrer les utilisateurs déjà partagés
//               final sharedUserIds = widget.vehicle.sharedWith
//                   .map((access) => access.userId)
//                   .toList();
//
//               final availableUsers = users.where((userDoc) {
//                 final userId = userDoc.id;
//                 return !sharedUserIds.contains(userId);
//               }).toList();
//
//               // Appliquer la recherche
//               final filteredUsers = _searchQuery.isEmpty
//                   ? availableUsers
//                   : availableUsers.where((userDoc) {
//                 final data = userDoc.data() as Map<String, dynamic>;
//                 final displayName = data['displayName']?.toString().toLowerCase() ?? '';
//                 final email = data['email']?.toString().toLowerCase() ?? '';
//                 return displayName.contains(_searchQuery) ||
//                     email.contains(_searchQuery);
//               }).toList();
//
//               if (filteredUsers.isEmpty) {
//                 return Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(Icons.search_off, size: 64, color: Colors.grey),
//                       const SizedBox(height: 16),
//                       Text(
//                         'Aucun utilisateur trouvé',
//                         style: TextStyle(color: Colors.grey[600]),
//                       ),
//                     ],
//                   ),
//                 );
//               }
//
//               return ListView.builder(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 itemCount: filteredUsers.length,
//                 itemBuilder: (context, index) {
//                   final userDoc = filteredUsers[index];
//                   final userData = userDoc.data() as Map<String, dynamic>;
//                   final userId = userDoc.id;
//                   final displayName = userData['name'] ?? 'Utilisateur sans nom';
//                   final email = userData['email'] ?? 'Email inconnu';
//                   final photoUrl = userData['photoUrl'];
//
//                   return Card(
//                     margin: const EdgeInsets.only(bottom: 8),
//                     child: ListTile(
//                       leading: photoUrl != null
//                           ? CircleAvatar(
//                         backgroundImage: NetworkImage(photoUrl),
//                       )
//                           : CircleAvatar(
//                         backgroundColor: _getColorFromName(displayName),
//                         child: Text(
//                           displayName.isNotEmpty
//                               ? displayName[0].toUpperCase()
//                               : '?',
//                           style: const TextStyle(color: Colors.white),
//                         ),
//                       ),
//                       title: Text(displayName),
//                       subtitle: Text(email),
//                       trailing: ElevatedButton(
//                         onPressed: () {
//                           _showShareConfirmationDialog(
//                             context,
//                             userId,
//                             displayName,
//                             email,
//                           );
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green,
//                           foregroundColor: Colors.white,
//                         ),
//                         child: const Text('Partager'),
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildSharedWithTab() {
//     final sharedWith = widget.vehicle.sharedWith;
//
//     if (sharedWith.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.group, size: 64, color: Colors.grey),
//             const SizedBox(height: 16),
//             const Text(
//               'Aucun utilisateur partagé',
//               style: TextStyle(fontSize: 18, color: Colors.grey),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Invitez des utilisateurs depuis l\'onglet "Inviter"',
//               style: TextStyle(color: Colors.grey[600]),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       );
//     }
//
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: sharedWith.length,
//       itemBuilder: (context, index) {
//         final access = sharedWith[index];
//         final displayName = access.displayName ?? 'Utilisateur sans nom';
//         final email = access.email;
//         final level = _permissionsToLevel(access.permissions);
//
//         return Card(
//           margin: const EdgeInsets.only(bottom: 8),
//           child: ListTile(
//             leading: CircleAvatar(
//               backgroundColor: _getColorFromName(displayName),
//               child: Text(
//                 displayName.isNotEmpty
//                     ? displayName[0].toUpperCase()
//                     : '?',
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ),
//             title: Text(displayName),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(email),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Niveau: ${_getAccessLevelLabel(level)}',
//                   style: TextStyle(
//                     color: _getAccessLevelColor(level),
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//             trailing: PopupMenuButton<String>(
//               onSelected: (value) {
//                 if (value == 'remove') {
//                   _showRemoveConfirmationDialog(context, access.userId, displayName);
//                 } else if (value == 'change_access') {
//                   final currentLevel = _permissionsToLevel(access.permissions);
//                   _showAccessLevelDialog(context, access.userId, displayName, currentLevel);
//                 }
//               },
//               itemBuilder: (context) => [
//                 const PopupMenuItem(
//                   value: 'change_access',
//                   child: Text('Changer les permissions'),
//                 ),
//                 const PopupMenuItem(
//                   value: 'remove',
//                   child: Text('Retirer l\'accès', style: TextStyle(color: Colors.red)),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   void _showShareConfirmationDialog(
//       BuildContext context,
//       String userId,
//       String displayName,
//       String email,
//       ) {
//     String selectedAccessLevel = 'read'; // Niveau par défaut
//
//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) {
//           return AlertDialog(
//             title: const Text('Confirmer le partage'),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Partager ce véhicule avec:'),
//                 const SizedBox(height: 8),
//                 ListTile(
//                   contentPadding: EdgeInsets.zero,
//                   leading: CircleAvatar(
//                     child: Text(displayName[0].toUpperCase()),
//                   ),
//                   title: Text(displayName),
//                   subtitle: Text(email,style: TextStyle(fontSize: 5),),
//                 ),
//                 const SizedBox(height: 16),
//                 const Text(
//                   'Niveau d\'accès:',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 8),
//                 DropdownButtonFormField<String>(
//                   value: selectedAccessLevel,
//                   items: [
//                     DropdownMenuItem(
//                       value: 'read',
//                       child: Row(
//                         children: [
//                           const Icon(Icons.visibility, color: Colors.blue),
//                           const SizedBox(width: 8),
//                           const Text('Lecture seule'),
//                         ],
//                       ),
//                     ),
//                     DropdownMenuItem(
//                       value: 'write',
//                       child: Row(
//                         children: [
//                           const Icon(Icons.edit, color: Colors.green),
//                           const SizedBox(width: 8),
//                           const Text('Lecture et écriture'),
//                         ],
//                       ),
//                     ),
//                   ],
//                   onChanged: (value) {
//                     setState(() {
//                       selectedAccessLevel = value!;
//                     });
//                   },
//                 ),
//                 const SizedBox(height: 8),
//                 _buildPermissionDescription(selectedAccessLevel),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Annuler'),
//               ),
//               ElevatedButton(
//                 onPressed: () async {
//                   Navigator.pop(context);
//                   await _shareWithUser(
//                     userId,
//                     displayName,
//                     email,
//                     selectedAccessLevel,
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   foregroundColor: Colors.white,
//                 ),
//                 child: const Text('Confirmer le partage'),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildPermissionDescription(String accessLevel) {
//     switch (accessLevel) {
//       case 'read':
//         return const Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.check, color: Colors.green, size: 20),
//                 SizedBox(width: 8),
//                 Text('Voir les interventions'),
//               ],
//             ),
//             Row(
//               children: [
//                 Icon(Icons.close, color: Colors.red, size: 20),
//                 SizedBox(width: 8),
//                 Text('Ajouter/modifier des interventions'),
//               ],
//             ),
//           ],
//         );
//       case 'write':
//         return const Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.check, color: Colors.green, size: 20),
//                 SizedBox(width: 8),
//                 Text('Voir les interventions'),
//               ],
//             ),
//             Row(
//               children: [
//                 Icon(Icons.check, color: Colors.green, size: 20),
//                 SizedBox(width: 8),
//                 Text('Ajouter de nouvelles interventions'),
//               ],
//             ),
//             Row(
//               children: [
//                 Icon(Icons.check, color: Colors.green, size: 20),
//                 SizedBox(width: 8),
//                 Text('Modifier ses propres interventions'),
//               ],
//             ),
//           ],
//         );
//       default:
//         return const SizedBox();
//     }
//   }
//
//   void _showRemoveConfirmationDialog(
//       BuildContext context,
//       String userId,
//       String displayName,
//       ) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Retirer l\'accès'),
//         content: Text(
//           'Retirer l\'accès à $displayName ? '
//               'Il/Elle ne pourra plus voir ni modifier ce véhicule.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Annuler'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               await _removeUser(userId, displayName);
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('Retirer l\'accès'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showAccessLevelDialog(
//       BuildContext context,
//       String userId,
//       String displayName,
//       String currentLevel,
//       ) {
//     String selectedAccessLevel = currentLevel;
//
//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) {
//           return AlertDialog(
//             title: Text('Permissions pour $displayName'),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 DropdownButtonFormField<String>(
//                   value: selectedAccessLevel,
//                   items: [
//                     DropdownMenuItem(
//                       value: 'read',
//                       child: Row(
//                         children: [
//                           const Icon(Icons.visibility, color: Colors.blue),
//                           const SizedBox(width: 8),
//                           const Text('Lecture seule'),
//                         ],
//                       ),
//                     ),
//                     DropdownMenuItem(
//                       value: 'write',
//                       child: Row(
//                         children: [
//                           const Icon(Icons.edit, color: Colors.green),
//                           const SizedBox(width: 8),
//                           const Text('Lecture et écriture'),
//                         ],
//                       ),
//                     ),
//                   ],
//                   onChanged: (value) {
//                     setState(() {
//                       selectedAccessLevel = value!;
//                     });
//                   },
//                 ),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Annuler'),
//               ),
//               ElevatedButton(
//                 onPressed: () async {
//                   Navigator.pop(context);
//                   await _updateAccessLevel(userId, selectedAccessLevel);
//                 },
//                 child: const Text('Mettre à jour'),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   Future<void> _shareWithUser(
//       String userId,
//       String displayName,
//       String email,
//       String level,
//       ) async {
//     try {
//       final vehicleRef = FirebaseFirestore.instance
//           .collection('vehicles')
//           .doc(widget.vehicle.id);
//
//       // Créer le nouvel accès
//       final newAccess = SharedAccess(
//         userId: userId,
//         email: email,
//         displayName: displayName,
//         permissions: _levelToPermissions(level),
//         sharedAt: DateTime.now(),
//       );
//
//       // Vérifier si l'utilisateur est déjà dans la liste
//       final existingIndex = widget.vehicle.sharedWith
//           .indexWhere((access) => access.userId == userId);
//
//       if (existingIndex >= 0) {
//         // Mettre à jour l'accès existant
//         final updatedSharedWith = List<SharedAccess>.from(widget.vehicle.sharedWith);
//         updatedSharedWith[existingIndex] = newAccess;
//
//         await vehicleRef.update({
//           'sharedWith': updatedSharedWith.map((access) => access.toMap()).toList(),
//         });
//
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Permissions mises à jour pour $displayName'),
//               backgroundColor: Colors.blue,
//             ),
//           );
//         }
//       } else {
//         // Ajouter le nouvel accès
//         final updatedSharedWith = [...widget.vehicle.sharedWith, newAccess];
//
//         await vehicleRef.update({
//           'sharedWith': updatedSharedWith.map((access) => access.toMap()).toList(),
//         });
//
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Véhicule partagé avec $displayName'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       }
//
//       // Actualiser l'affichage
//       if (mounted) {
//         setState(() {});
//       }
//
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Erreur: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   Future<void> _removeUser(String userId, String displayName) async {
//     try {
//       final vehicleRef = FirebaseFirestore.instance
//           .collection('vehicles')
//           .doc(widget.vehicle.id);
//
//       // Filtrer pour retirer l'utilisateur
//       final updatedSharedWith = widget.vehicle.sharedWith
//           .where((access) => access.userId != userId)
//           .toList();
//
//       await vehicleRef.update({
//         'sharedWith': updatedSharedWith.map((access) => access.toMap()).toList(),
//       });
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Accès retiré pour $displayName'),
//             backgroundColor: Colors.orange,
//           ),
//         );
//
//         // Actualiser l'affichage
//         setState(() {});
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Erreur: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   Future<void> _updateAccessLevel(
//       String userId,
//       String newLevel,
//       ) async {
//     try {
//       final vehicleRef = FirebaseFirestore.instance
//           .collection('vehicles')
//           .doc(widget.vehicle.id);
//
//       // Récupérer l'accès actuel et le mettre à jour
//       final updatedSharedWith = widget.vehicle.sharedWith.map((access) {
//         if (access.userId == userId) {
//           return access.copyWith(permissions: _levelToPermissions(newLevel));
//         }
//         return access;
//       }).toList();
//
//       await vehicleRef.update({
//         'sharedWith': updatedSharedWith.map((access) => access.toMap()).toList(),
//       });
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Permissions mises à jour'),
//             backgroundColor: Colors.blue,
//           ),
//         );
//
//         // Actualiser l'affichage
//         setState(() {});
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Erreur: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   // Méthodes de conversion entre niveau d'accès et permissions
//   String _permissionsToLevel(List<String> permissions) {
//     if (permissions.contains('edit')) {
//       return 'write';
//     } else {
//       return 'read';
//     }
//   }
//
//   List<String> _levelToPermissions(String level) {
//     if (level == 'write') {
//       return writePermissions;
//     } else {
//       return readPermissions;
//     }
//   }
//
//   Color _getColorFromName(String name) {
//     final colors = [
//       Colors.blue,
//       Colors.red,
//       Colors.green,
//       Colors.orange,
//       Colors.purple,
//       Colors.teal,
//       Colors.pink,
//       Colors.indigo,
//     ];
//
//     if (name.isEmpty) return Colors.grey;
//
//     final hash = name.codeUnits.fold(0, (a, b) => a + b);
//     return colors[hash % colors.length];
//   }
//
//   String _getAccessLevelLabel(String accessLevel) {
//     switch (accessLevel) {
//       case 'read':
//         return 'Lecture seule';
//       case 'write':
//         return 'Lecture et écriture';
//       default:
//         return 'Inconnu';
//     }
//   }
//
//   Color _getAccessLevelColor(String accessLevel) {
//     switch (accessLevel) {
//       case 'read':
//         return Colors.blue;
//       case 'write':
//         return Colors.green;
//       default:
//         return Colors.grey;
//     }
//   }
// }

// lib/features/vehicles/presentation/screens/shared_vehicles_list_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_state_notifier.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../application/vehicle_providers.dart';
import '../../domain/models/vehicule_model.dart';


class SharedVehiclesListScreen extends ConsumerStatefulWidget {
  const SharedVehiclesListScreen({super.key});

  @override
  ConsumerState<SharedVehiclesListScreen> createState() => _SharedVehiclesListScreenState();
}

class _SharedVehiclesListScreenState extends ConsumerState<SharedVehiclesListScreen> {
  @override
  Widget build(BuildContext context) {
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

        final vehiclesAsync = ref.watch(vehiclesSharedWithMeProvider(user.uid));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Véhicules partagés avec moi'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(vehiclesSharedWithMeProvider(user.uid)),
              ),
            ],
          ),
          body: vehiclesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: $err'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(sharedVehiclesStreamProvider(user.uid)),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
            data: (vehicles) {
              if (vehicles.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.directions_car,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucun véhicule partagé',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Les propriétaires de véhicules peuvent vous partager\nleurs véhicules depuis l\'application.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  return _buildVehicleCard(context, vehicle);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildVehicleCard(BuildContext context, Vehicle vehicle) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: vehicle.mainPhotoUrl != null
            ? CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(vehicle.mainPhotoUrl!),
        )
            : CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: const Icon(Icons.directions_car, color: Colors.grey),
        ),
        title: Text('${vehicle.brand} ${vehicle.model}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vehicle.plateNumber != null) Text(vehicle.plateNumber!),
             ...[
              const SizedBox(height: 4),
              Text(
                'Propriétaire: ${vehicle.ownerName ?? vehicle.ownerId}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Naviguer vers les détails ou la maintenance
          context.push('/vehicle/${vehicle.id}');
        },
      ),
    );
  }
}