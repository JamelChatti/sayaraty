import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/shared_access_model.dart';
import '../domain/models/vehicule_model.dart';

final vehicleServiceProvider = Provider<VehicleService>((ref) {
  return VehicleService();
});

/// 🔹 Véhicule par ID
final vehicleByIdStreamProvider =
StreamProvider.autoDispose.family<Vehicle?, String>((ref, vehicleId) {
  return FirebaseFirestore.instance
      .collection('vehicles')
      .doc(vehicleId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;
    return Vehicle.fromMap(snapshot.data()!, snapshot.id);
  });
});

/// 🔹 Véhicules d’un utilisateur
final vehiclesStreamProvider =
StreamProvider.autoDispose.family<List<Vehicle>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('vehicles')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => Vehicle.fromMap(doc.data(), doc.id))
        .toList();
  });
});
// Dans vehicle_service.dart (au niveau racine, avec les autres providers)
// final sharedVehiclesStreamProvider = StreamProvider.autoDispose.family<List<Vehicle>, String>((ref, proId) {
//   return FirebaseFirestore.instance
//       .collection('vehicles')
//       .where('sharedWith.userId', isEqualTo: proId)  // Recherche du userId dans le champ sharedWith
//       .snapshots()
//       .map((snapshot) {
//     return snapshot.docs.map((doc) {
//       final data = doc.data();
//       data['id'] = doc.id;
//       return Vehicle.fromMap(data, doc.id);
//     }).toList();
//   });
// });

final sharedVehiclesStreamProvider = StreamProvider.autoDispose.family<List<Vehicle>, String>((ref, proId) {
  return FirebaseFirestore.instance
      .collection('vehicles')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) {
      final data = doc.data();
      final sharedWith = (data['sharedWith'] as List<dynamic>)
          .map((access) => SharedAccess.fromMap(Map<String, dynamic>.from(access)))
          .toList();

      // Filtrer les véhicules partagés avec le proId
      final sharedWithPro = sharedWith.firstWhere(
            (access) => access.userId == proId,
        orElse: () => SharedAccess( // Remplacer null par un objet par défaut
          userId: '',
          email: '',
          displayName: '',
          permissions: [],
          sharedAt: DateTime.now(),
        ),
      );

      // Si le véhicule est partagé avec le professionnel, le retourner
      if (sharedWithPro.userId == proId) {
        data['id'] = doc.id;
        return Vehicle.fromMap(data, doc.id); // Retourner le véhicule si partagé
      }
      return null; // Ne pas retourner de véhicule s'il n'est pas partagé
    })
        .where((vehicle) => vehicle != null) // Filtrer les nulls
        .toList()
        .cast<Vehicle>(); // Cast à List<Vehicle> sans nulls
  });
});


class VehicleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addVehicle(Vehicle vehicle) async {
    await _firestore
        .collection('vehicles')
        .doc(vehicle.id)
        .set(vehicle.toMap());
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    await _firestore
        .collection('vehicles')
        .doc(vehicle.id)
        .update(vehicle.toMap());
  }

  Future<void> deleteVehicle(String vehicleId) async {
    await _firestore.collection('vehicles').doc(vehicleId).delete();
  }

  /// 🔹 Mise à jour des pièces jointes
  Future<void> updateVehicleAttachments(
      String vehicleId,
      List<String> attachments,
      ) async {
    await _firestore.collection('vehicles').doc(vehicleId).update({
      'attachments': attachments,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🔹 Stream alternatif (si besoin hors Riverpod)
  Stream<List<Vehicle>> watchUserVehicles(String userId) {
    return _firestore
        .collection('vehicles')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => Vehicle.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  // Pour mettre à jour le partage
  Future<void> updateVehicleSharedWith({
    required String vehicleId,
    required List<SharedAccess> sharedWith,
  }) async {
    await _firestore.collection('vehicles').doc(vehicleId).update({
      'sharedWith': sharedWith.map((access) => access.toMap()).toList(),
    });
  }

  // Obtenir les véhicules partagés avec un utilisateur


  // ✅ Obtenir les véhicules partagés avec un utilisateur
  Stream<List<Vehicle>> getSharedVehicles(String userId) {
    try {
      return _firestore
          .collection('vehicles')
          .where('sharedWithUserIds', arrayContains: userId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Vehicle.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      print('❌ Erreur getSharedVehicles: $e');
      return Stream.value([]);
    }
  }


}
