import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
final sharedVehiclesStreamProvider = StreamProvider.autoDispose.family<List<Vehicle>, String>((ref, proId) {
  return FirebaseFirestore.instance
      .collection('vehicles')
      .where('sharedWith', arrayContains: proId)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Vehicle.fromMap(data,doc.id);
    }).toList();
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
}
