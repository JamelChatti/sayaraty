// lib/features/maintenance/application/maintenance_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/maintenance_model.dart';

// 🔹 Provider Riverpod pour le service
final maintenanceServiceProvider = Provider<MaintenanceService>((ref) {
  return MaintenanceService();
});

// 🔹 Provider Stream pour écouter les maintenances d'un véhicule
// ✅ Changer le type de paramètre : utiliser une liste ou un objet personnalisé
final maintenancesStreamProvider = StreamProvider.autoDispose.family<List<Maintenance>, ({String userId, String vehicleId})>((ref, args) {
return ref.watch(maintenanceServiceProvider).watchMaintenances(args.vehicleId, args.userId);
});

// Dans maintenance_service.dart
final maintenanceByIdStreamProvider = StreamProvider.autoDispose.family<Maintenance?, String>((ref, maintenanceId) {
  return FirebaseFirestore.instance
      .collection('maintenances')
      .doc(maintenanceId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;
    final data = snapshot.data()!;
    data['id'] = snapshot.id;
    return Maintenance.fromMap(data);
  });
});

class MaintenanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Ajouter une nouvelle maintenance
  Future<void> addMaintenance(Maintenance maintenance) async {
    final docRef = _firestore.collection('maintenances').doc(maintenance.id);
    await docRef.set(maintenance.toMap());
  }

  // ✅ Mettre à jour une maintenance existante
  Future<void> updateMaintenance(Maintenance maintenance) async {
    final docRef = _firestore.collection('maintenances').doc(maintenance.id);
    await docRef.update(maintenance.toMap());
  }

  // ✅ Supprimer une maintenance
  Future<void> deleteMaintenance(String maintenanceId) async {
    await _firestore.collection('maintenances').doc(maintenanceId).delete();
  }

  // ✅ Lire les maintenances d'un véhicule (triées par date DESC)
  Stream<List<Maintenance>> watchMaintenances(String vehicleId, String userId) {
    return _firestore
        .collection('maintenances')
        .where('userId', isEqualTo: userId)
        .where('vehicleId', isEqualTo: vehicleId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // 🔑 Injection de l'ID du document
        return Maintenance.fromMap(data);
      }).toList();
    });
  }

  // ✅ Lire les maintenances planifiées (non terminées) pour un utilisateur
  Stream<List<Maintenance>> watchPlannedMaintenances(String userId) {
    return _firestore
        .collection('maintenances')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'planned')
        .orderBy('nextDueDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Maintenance.fromMap(data);
      }).toList();
    });
  }


}