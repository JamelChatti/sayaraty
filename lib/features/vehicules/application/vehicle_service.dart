// lib/features/vehicles/application/vehicle_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/vehicule_model.dart';

final vehicleServiceProvider = Provider<VehicleService>((ref) {
  return VehicleService();
});

class VehicleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addVehicle(Vehicle vehicle) async {
    await _firestore.collection('vehicles').doc(vehicle.id).set(vehicle.toMap());
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    await _firestore.collection('vehicles').doc(vehicle.id).update(vehicle.toMap());
  }

  Future<void> deleteVehicle(String vehicleId) async {
    await _firestore.collection('vehicles').doc(vehicleId).delete();
  }

  // lib/features/vehicles/application/vehicle_service.dart
  // Dans le StreamProvider
  final vehiclesStreamProvider = StreamProvider.autoDispose.family<List<Vehicle>, String>((ref, userId) {
    return FirebaseFirestore.instance
        .collection('vehicles')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // ✅ Injection de l'ID
        return Vehicle.fromMap(data, doc.id);
      }).toList();
    });
  });


  Stream<List<Vehicle>> watchUserVehicles(String userId) {
    return _firestore
        .collection('vehicles')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => Vehicle.fromMap(doc.data(),doc.id ))
          .toList(),
    );
  }

}