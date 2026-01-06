// // lib/features/vehicles/application/sharing_service.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../auth/application/auth_service.dart';
// import '../domain/models/shared_access_model.dart';
// import '../domain/models/vehicule_model.dart';
//
// final sharingServiceProvider = Provider<SharingService>((ref) {
//   return SharingService(ref);
// });
//
// class SharingService {
//   final Ref _ref;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   SharingService(this._ref);
//
//   // Partager un véhicule avec un autre utilisateur
//   Future<void> shareVehicle({
//     required String vehicleId,
//     required String userEmail,
//     required List<String> permissions,
//     String? displayName,
//   }) async {
//     try {
//       // 1. Trouver l'utilisateur par email
//       final userSnapshot = await _firestore
//           .collection('users')
//           .where('email', isEqualTo: userEmail.toLowerCase())
//           .limit(1)
//           .get();
//
//       if (userSnapshot.docs.isEmpty) {
//         throw Exception('Utilisateur non trouvé');
//       }
//
//       final targetUser = userSnapshot.docs.first;
//       final currentUser = _ref.read(authServiceProvider).currentUser;
//
//       if (currentUser == null) {
//         throw Exception('Utilisateur non connecté');
//       }
//
//       // 2. Vérifier qu'on ne partage pas avec soi-même
//       if (targetUser.id == currentUser.uid) {
//         throw Exception('Vous ne pouvez pas partager avec vous-même');
//       }
//
//       // 3. Vérifier que l'utilisateur est propriétaire
//       final vehicleDoc = await _firestore
//           .collection('vehicles')
//           .doc(vehicleId)
//           .get();
//
//       final vehicleData = vehicleDoc.data();
//       if (vehicleData == null) {
//         throw Exception('Véhicule non trouvé');
//       }
//
//       if (vehicleData['ownerId'] != currentUser.uid) {
//         throw Exception('Vous n\'êtes pas propriétaire de ce véhicule');
//       }
//
//       // 4. Vérifier si l'utilisateur a déjà accès
//       final existingShared = Vehicle.parseSharedWith(vehicleData['sharedWith']);
//
//       if (existingShared.any((access) => access.userId == targetUser.id)) {
//         throw Exception('Cet utilisateur a déjà accès à ce véhicule');
//       }
//
//       // 5. Créer l'objet SharedAccess
//       final userData = targetUser.data() as Map<String, dynamic>;
//       final sharedAccess = SharedAccess(
//         userId: targetUser.id,
//         email: userEmail,
//         displayName: displayName ?? userData['displayName'] ?? userData['name'],
//         permissions: permissions,
//         sharedAt: DateTime.now(),
//       );
//
//       // 6. Récupérer les accès actuels
//       final currentShared = existingShared;
//       final updatedShared = [...currentShared, sharedAccess];
//
//       // 7. Mettre à jour dans Firestore
//       await _firestore.collection('vehicles').doc(vehicleId).update({
//         'sharedWith': updatedShared.map((access) => access.toMap()).toList(),
//       });
//
//       // 8. Mettre à jour l'index de recherche
//       await updateVehicleSearchIndex(vehicleId);
//
//     } catch (e) {
//       print('❌ Erreur lors du partage: $e');
//       rethrow;
//     }
//   }
//
//   // Retirer l'accès partagé
//   Future<void> revokeAccess({
//     required String vehicleId,
//     required String userId,
//   }) async {
//     try {
//       // Récupérer le véhicule
//       final vehicleDoc = await _firestore
//           .collection('vehicles')
//           .doc(vehicleId)
//           .get();
//
//       final vehicleData = vehicleDoc.data();
//       if (vehicleData == null) {
//         throw Exception('Véhicule non trouvé');
//       }
//
//       final sharedList = Vehicle.parseSharedWith(vehicleData['sharedWith']);
//
//       // Trouver l'accès à retirer
//       final accessToRemove = sharedList.firstWhere(
//             (access) => access.userId == userId,
//         orElse: () => SharedAccess(
//           userId: '',
//           email: '',
//           permissions: [],
//           sharedAt: DateTime.now(),
//         ),
//       );
//
//       if (accessToRemove.userId.isEmpty) {
//         throw Exception('Accès non trouvé');
//       }
//
//       // Filtrer pour retirer l'utilisateur
//       final updatedShared = sharedList.where((access) => access.userId != userId).toList();
//
//       // Mettre à jour dans Firestore
//       await _firestore.collection('vehicles').doc(vehicleId).update({
//         'sharedWith': updatedShared.map((access) => access.toMap()).toList(),
//       });
//
//       // Mettre à jour l'index
//       await updateVehicleSearchIndex(vehicleId);
//
//     } catch (e) {
//       print('❌ Erreur lors de la révocation: $e');
//       rethrow;
//     }
//   }
//
//   // Vérifier si un utilisateur a accès à un véhicule
//   Future<bool> checkUserAccess({
//     required String vehicleId,
//     required String userId,
//   }) async {
//     try {
//       final vehicleDoc = await _firestore
//           .collection('vehicles')
//           .doc(vehicleId)
//           .get();
//
//       final vehicleData = vehicleDoc.data();
//       if (vehicleData == null) return false;
//
//       // Propriétaire a toujours accès
//       if (vehicleData['ownerId'] == userId) return true;
//
//       // Vérifier les accès partagés
//       final sharedList = Vehicle.parseSharedWith(vehicleData['sharedWith']);
//       return sharedList.any((access) => access.userId == userId);
//     } catch (e) {
//       print('❌ Erreur lors de la vérification d\'accès: $e');
//       return false;
//     }
//   }
//
//   // Obtenir les permissions d'un utilisateur sur un véhicule
//   Future<List<String>> getUserPermissions({
//     required String vehicleId,
//     required String userId,
//   }) async {
//     try {
//       final vehicleDoc = await _firestore
//           .collection('vehicles')
//           .doc(vehicleId)
//           .get();
//
//       final vehicleData = vehicleDoc.data();
//       if (vehicleData == null) return [];
//
//       // Propriétaire a toutes les permissions
//       if (vehicleData['ownerId'] == userId) {
//         return ['view', 'edit', 'delete', 'share'];
//       }
//
//       // Vérifier les permissions partagées
//       final sharedList = Vehicle.parseSharedWith(vehicleData['sharedWith']);
//       final userAccess = sharedList.firstWhere(
//             (access) => access.userId == userId,
//         orElse: () => SharedAccess(
//           userId: '',
//           email: '',
//           permissions: [],
//           sharedAt: DateTime.now(),
//         ),
//       );
//
//       return userAccess.permissions;
//     } catch (e) {
//       print('❌ Erreur lors de la récupération des permissions: $e');
//       return [];
//     }
//   }
//
//   // Obtenir les véhicules partagés avec l'utilisateur courant
//   Stream<List<Map<String, dynamic>>> getSharedVehicles(String userId) {
//     return _firestore
//         .collection('vehicles')
//         .snapshots()
//         .map((snapshot) {
//       return snapshot.docs.where((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//
//         // Si c'est le propriétaire
//         if (data['ownerId'] == userId) return true;
//
//         // Vérifier si l'utilisateur est dans sharedWith
//         final sharedList = Vehicle.parseSharedWith(data['sharedWith']);
//         return sharedList.any((access) => access.userId == userId);
//       }).map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         data['id'] = doc.id;
//         return data;
//       }).toList();
//     });
//   }
//
//   // Méthode plus performante avec index
//   Future<void> updateVehicleSearchIndex(String vehicleId) async {
//     try {
//       final vehicleDoc = await _firestore
//           .collection('vehicles')
//           .doc(vehicleId)
//           .get();
//
//       final vehicleData = vehicleDoc.data();
//       if (vehicleData == null) return;
//
//       final sharedList = Vehicle.parseSharedWith(vehicleData['sharedWith']);
//       final userIds = sharedList.map((access) => access.userId).toList();
//
//       await _firestore.collection('vehicles').doc(vehicleId).update({
//         'sharedWithUserIds': userIds,
//       });
//     } catch (e) {
//       print('❌ Erreur lors de la mise à jour de l\'index: $e');
//     }
//   }
//
//   // Version simple avec index précalculé
//   Stream<List<Map<String, dynamic>>> getSharedVehiclesSimple(String userId) {
//     return _firestore
//         .collection('vehicles')
//         .where('sharedWithUserIds', arrayContains: userId)
//         .snapshots()
//         .map((snapshot) => snapshot.docs.map((doc) {
//       final data = doc.data() as Map<String, dynamic>;
//       data['id'] = doc.id;
//       return data;
//     }).toList());
//   }
//
//   // Obtenir la liste des utilisateurs avec accès
//   Future<List<SharedAccess>> getSharedUsers(String vehicleId) async {
//     try {
//       final vehicleDoc = await _firestore
//           .collection('vehicles')
//           .doc(vehicleId)
//           .get();
//
//       final vehicleData = vehicleDoc.data();
//       if (vehicleData == null) return [];
//
//       return Vehicle.parseSharedWith(vehicleData['sharedWith']);
//     } catch (e) {
//       print('❌ Erreur lors de la récupération des utilisateurs partagés: $e');
//       return [];
//     }
//   }
//
//   // Mettre à jour les permissions d'un utilisateur
//   Future<void> updateUserPermissions({
//     required String vehicleId,
//     required String userId,
//     required List<String> permissions,
//   }) async {
//     try {
//       final vehicleDoc = await _firestore
//           .collection('vehicles')
//           .doc(vehicleId)
//           .get();
//
//       final vehicleData = vehicleDoc.data();
//       if (vehicleData == null) {
//         throw Exception('Véhicule non trouvé');
//       }
//
//       final sharedList = Vehicle.parseSharedWith(vehicleData['sharedWith']);
//
//       // Trouver et mettre à jour l'accès
//       final updatedList = sharedList.map((access) {
//         if (access.userId == userId) {
//           return access.copyWith(permissions: permissions);
//         }
//         return access;
//       }).toList();
//
//       await _firestore.collection('vehicles').doc(vehicleId).update({
//         'sharedWith': updatedList.map((access) => access.toMap()).toList(),
//       });
//
//       // Mettre à jour l'index
//       await updateVehicleSearchIndex(vehicleId);
//     } catch (e) {
//       throw Exception('Erreur lors de la mise à jour des permissions: $e');
//     }
//   }
//
//   // Migrer les anciennes données (List<String>) vers le nouveau format
//   Future<void> migrateSharedWithData() async {
//     try {
//       final vehiclesSnapshot = await _firestore.collection('vehicles').get();
//
//       for (final doc in vehiclesSnapshot.docs) {
//         final data = doc.data();
//         final sharedWith = data['sharedWith'];
//
//         if (sharedWith != null && sharedWith is List) {
//           // Vérifier si c'est encore l'ancien format (List<String>)
//           if (sharedWith.isNotEmpty && sharedWith.first is String) {
//             final newSharedWith = sharedWith.map((userId) {
//               return SharedAccess(
//                 userId: userId.toString(),
//                 email: '',
//                 displayName: null,
//                 permissions: ['view'],
//                 sharedAt: DateTime.now(),
//               ).toMap();
//             }).toList();
//
//             await _firestore.collection('vehicles').doc(doc.id).update({
//               'sharedWith': newSharedWith,
//             });
//
//             print('✅ Migré le véhicule: ${doc.id}');
//           }
//         }
//       }
//
//       print('✅ Migration terminée');
//     } catch (e) {
//       print('❌ Erreur lors de la migration: $e');
//     }
//   }
// }

// lib/features/vehicles/application/sharing_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_service.dart';
import '../domain/models/shared_access_model.dart';
import '../domain/models/vehicule_model.dart';

final sharingServiceProvider = Provider<SharingService>((ref) {
  return SharingService(ref);
});

class SharingService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SharingService(this._ref);

  // Partager un véhicule avec un autre utilisateur
  Future<void> shareVehicle({
    required String vehicleId,
    required String userEmail,
    required List<String> permissions,
    String? displayName,
  }) async {
    try {
      // 1. Trouver l'utilisateur par email
      final userSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: userEmail.toLowerCase())
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        throw Exception('Utilisateur non trouvé');
      }

      final targetUser = userSnapshot.docs.first;
      final currentUser = _ref.read(authServiceProvider).currentUser;

      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // 2. Vérifier qu'on ne partage pas avec soi-même
      if (targetUser.id == currentUser.uid) {
        throw Exception('Vous ne pouvez pas partager avec vous-même');
      }

      // 3. Vérifier que l'utilisateur est propriétaire
      final vehicleDoc = await _firestore
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      final vehicleData = vehicleDoc.data();
      if (vehicleData == null) {
        throw Exception('Véhicule non trouvé');
      }

      if (vehicleData['ownerId'] != currentUser.uid) {
        throw Exception('Vous n\'êtes pas propriétaire de ce véhicule');
      }

      // 4. Vérifier si l'utilisateur a déjà accès
      final existingShared = Vehicle.parseSharedWith(vehicleData['sharedWith']);

      if (existingShared.any((access) => access.userId == targetUser.id)) {
        throw Exception('Cet utilisateur a déjà accès à ce véhicule');
      }

      // 5. Créer l'objet SharedAccess
      final userData = targetUser.data();
      final sharedAccess = SharedAccess(
        userId: targetUser.id,
        email: userEmail,
        displayName: displayName ?? userData['displayName'] ?? userData['name'],
        permissions: permissions,
        sharedAt: DateTime.now(),
      );

      // 6. Récupérer les accès actuels
      final currentShared = existingShared;
      final updatedShared = [...currentShared, sharedAccess];

      // 7. Mettre à jour dans Firestore
      await _firestore.collection('vehicles').doc(vehicleId).update({
        'sharedWith': updatedShared.map((access) => access.toMap()).toList(),
      });

      // 8. Mettre à jour l'index de recherche
      await updateVehicleSearchIndex(vehicleId);

    } catch (e) {
      print('❌ Erreur lors du partage: $e');
      rethrow;
    }
  }

  // Retirer l'accès partagé
  Future<void> revokeAccess({
    required String vehicleId,
    required String userId,
  }) async {
    try {
      // Récupérer le véhicule
      final vehicleDoc = await _firestore
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      final vehicleData = vehicleDoc.data();
      if (vehicleData == null) {
        throw Exception('Véhicule non trouvé');
      }

      final sharedList = Vehicle.parseSharedWith(vehicleData['sharedWith']);

      // Trouver l'accès à retirer
      final accessToRemove = sharedList.firstWhere(
            (access) => access.userId == userId,
        orElse: () => SharedAccess(
          userId: '',
          email: '',
          permissions: [],
          sharedAt: DateTime.now(),
        ),
      );

      if (accessToRemove.userId.isEmpty) {
        throw Exception('Accès non trouvé');
      }

      // Filtrer pour retirer l'utilisateur
      final updatedShared = sharedList.where((access) => access.userId != userId).toList();

      // Mettre à jour dans Firestore
      await _firestore.collection('vehicles').doc(vehicleId).update({
        'sharedWith': updatedShared.map((access) => access.toMap()).toList(),
      });

      // Mettre à jour l'index
      await updateVehicleSearchIndex(vehicleId);

    } catch (e) {
      print('❌ Erreur lors de la révocation: $e');
      rethrow;
    }
  }

  // Vérifier si un utilisateur a accès à un véhicule
  Future<bool> checkUserAccess({
    required String vehicleId,
    required String userId,
  }) async {
    try {
      final vehicleDoc = await _firestore
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      final vehicleData = vehicleDoc.data();
      if (vehicleData == null) return false;

      // Propriétaire a toujours accès
      if (vehicleData['ownerId'] == userId) return true;

      // Vérifier les accès partagés
      final sharedList = Vehicle.parseSharedWith(vehicleData['sharedWith']);
      return sharedList.any((access) => access.userId == userId);
    } catch (e) {
      print('❌ Erreur lors de la vérification d\'accès: $e');
      return false;
    }
  }

  // Obtenir les permissions d'un utilisateur sur un véhicule
  Future<List<String>> getUserPermissions({
    required String vehicleId,
    required String userId,
  }) async {
    try {
      final vehicleDoc = await _firestore
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      final vehicleData = vehicleDoc.data();
      if (vehicleData == null) return [];

      // Propriétaire a toutes les permissions
      if (vehicleData['ownerId'] == userId) {
        return ['view', 'edit', 'delete', 'share'];
      }

      // Vérifier les permissions partagées
      final sharedList = Vehicle.parseSharedWith(vehicleData['sharedWith']);
      final userAccess = sharedList.firstWhere(
            (access) => access.userId == userId,
        orElse: () => SharedAccess(
          userId: '',
          email: '',
          permissions: [],
          sharedAt: DateTime.now(),
        ),
      );

      return userAccess.permissions;
    } catch (e) {
      print('❌ Erreur lors de la récupération des permissions: $e');
      return [];
    }
  }

  // Obtenir les véhicules partagés avec l'utilisateur courant
  Stream<List<Map<String, dynamic>>> getSharedVehicles(String userId) {
    return _firestore
        .collection('vehicles')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data() ;

        // Si c'est le propriétaire
        if (data['ownerId'] == userId) return true;

        // Vérifier si l'utilisateur est dans sharedWith
        final sharedList = Vehicle.parseSharedWith(data['sharedWith']);
        return sharedList.any((access) => access.userId == userId);
      }).map((doc) {
        final data = doc.data() ;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Méthode plus performante avec index
  Future<void> updateVehicleSearchIndex(String vehicleId) async {
    try {
      final vehicleDoc = await _firestore
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      final vehicleData = vehicleDoc.data();
      if (vehicleData == null) return;

      final sharedList = Vehicle.parseSharedWith(vehicleData['sharedWith']);
      final userIds = sharedList.map((access) => access.userId).toList();

      await _firestore.collection('vehicles').doc(vehicleId).update({
        'sharedWithUserIds': userIds,
      });
    } catch (e) {
      print('❌ Erreur lors de la mise à jour de l\'index: $e');
    }
  }

  // Version simple avec index précalculé
  Stream<List<Map<String, dynamic>>> getSharedVehiclesSimple(String userId) {
    return _firestore
        .collection('vehicles')
        .where('sharedWithUserIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data() ;
      data['id'] = doc.id;
      return data;
    }).toList());
  }

  // Obtenir la liste des utilisateurs avec accès
  Future<List<SharedAccess>> getSharedUsers(String vehicleId) async {
    try {
      final vehicleDoc = await _firestore
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      final vehicleData = vehicleDoc.data();
      if (vehicleData == null) return [];

      return Vehicle.parseSharedWith(vehicleData['sharedWith']);
    } catch (e) {
      print('❌ Erreur lors de la récupération des utilisateurs partagés: $e');
      return [];
    }
  }

  // Mettre à jour les permissions d'un utilisateur
  Future<void> updateUserPermissions({
    required String vehicleId,
    required String userId,
    required List<String> permissions,
  }) async {
    try {
      final vehicleDoc = await _firestore
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      final vehicleData = vehicleDoc.data();
      if (vehicleData == null) {
        throw Exception('Véhicule non trouvé');
      }

      final sharedList = Vehicle.parseSharedWith(vehicleData['sharedWith']);

      // Trouver et mettre à jour l'accès
      final updatedList = sharedList.map((access) {
        if (access.userId == userId) {
          return access.copyWith(permissions: permissions);
        }
        return access;
      }).toList();

      await _firestore.collection('vehicles').doc(vehicleId).update({
        'sharedWith': updatedList.map((access) => access.toMap()).toList(),

      });

      // Mettre à jour l'index
      await updateVehicleSearchIndex(vehicleId);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des permissions: $e');
    }
  }

  // Migrer les anciennes données (List<String>) vers le nouveau format
  Future<void> migrateSharedWithData() async {
    try {
      final vehiclesSnapshot = await _firestore.collection('vehicles').get();

      for (final doc in vehiclesSnapshot.docs) {
        final data = doc.data();
        final sharedWith = data['sharedWith'];

        if (sharedWith != null && sharedWith is List) {
          // Vérifier si c'est encore l'ancien format (List<String>)
          if (sharedWith.isNotEmpty && sharedWith.first is String) {
            final newSharedWith = sharedWith.map((userId) {
              return SharedAccess(
                userId: userId.toString(),
                email: '',
                displayName: null,
                permissions: ['view'],
                sharedAt: DateTime.now(),
              ).toMap();
            }).toList();

            await _firestore.collection('vehicles').doc(doc.id).update({
              'sharedWith': newSharedWith,
            });

            print('✅ Migré le véhicule: ${doc.id}');
          }
        }
      }

      print('✅ Migration terminée');
    } catch (e) {
      print('❌ Erreur lors de la migration: $e');
    }
  }

  // À la fin de sharing_service.dart, après la classe SharingService

// Providers pour Riverpod
  final sharedVehiclesStreamProvider = StreamProvider.autoDispose
      .family<List<Vehicle>, String>((ref, userId) {
    final sharingService = ref.read(sharingServiceProvider);
    return sharingService.getSharedVehicles(userId).map((list) {
      return list.map((data) => Vehicle.fromMap(data, data['id'] as String)).toList();
    });
  });

  final ownedVehiclesStreamProvider = StreamProvider.autoDispose
      .family<List<Vehicle>, String>((ref, userId) {
    final firestore = FirebaseFirestore.instance;
    return firestore
        .collection('vehicles')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Vehicle.fromMap(
          doc.data() ,
          doc.id,
        );
      }).toList();
    });
  });

}