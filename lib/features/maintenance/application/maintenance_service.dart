// lib/features/maintenance/application/maintenance_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/maintenance_model.dart';

// 🔹 Provider Riverpod pour le service
final maintenanceServiceProvider = Provider<MaintenanceService>((ref) {
  return MaintenanceService();
});

// 🔹 Provider Stream pour écouter les maintenances d'un véhicule
final maintenancesStreamProvider = StreamProvider.autoDispose
    .family<List<Maintenance>, ({String userId, String vehicleId})>((
      ref,
      args,
    ) {
      return ref
          .watch(maintenanceServiceProvider)
          .watchMaintenances(args.vehicleId, args.userId);
    });

/// Toutes les interventions d'un véhicule (tous auteurs) — utile pour la conso.
final vehicleMaintenancesStreamProvider = StreamProvider.autoDispose
    .family<List<Maintenance>, String>((ref, vehicleId) {
      return ref
          .watch(maintenanceServiceProvider)
          .watchMaintenancesByVehicle(vehicleId);
    });

// ✅ NOUVEAU: Provider pour les professionnels
// Dans maintenance_service.dart
// ✅ CORRIGÉ : Utiliser un record nommé au lieu d'un Map
final professionalMaintenancesStreamProvider =
    StreamProvider.family<
      List<Maintenance>,
      ({String professionalId, String vehicleId, String clientId})
    >((ref, args) {
      final service = ref.watch(maintenanceServiceProvider);

      return service.getProfessionalMaintenancesStream(
        professionalId: args.professionalId,
        vehicleId: args.vehicleId,
        clientId: args.clientId,
      );
    });
// Provider pour une maintenance spécifique
final maintenanceByIdStreamProvider = StreamProvider.autoDispose
    .family<Maintenance?, String>((ref, maintenanceId) {
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
    await _firestore
        .collection('maintenances')
        .doc(maintenance.id)
        .update(maintenance.toMap());
  }

  // ✅ Supprimer une maintenance
  Future<void> deleteMaintenance(String maintenanceId) async {
    await _firestore.collection('maintenances').doc(maintenanceId).delete();
  }

  /// Supprime le rappel d'échéance après intervention effectuée.
  Future<void> clearDueReminder(String maintenanceId) async {
    await _firestore.collection('maintenances').doc(maintenanceId).update({
      'nextDueDate': FieldValue.delete(),
      'nextDueMileage': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Met à jour uniquement la liste des pièces jointes.
  Future<void> updateMaintenanceAttachments(
    String maintenanceId,
    List<String> attachments,
  ) async {
    await _firestore.collection('maintenances').doc(maintenanceId).update({
      'attachments': attachments,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Toutes les maintenances d'un véhicule, sans filtre userId.
  Stream<List<Maintenance>> watchMaintenancesByVehicle(String vehicleId) {
    return _firestore
        .collection('maintenances')
        .where('vehicleId', isEqualTo: vehicleId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Maintenance.fromMap(data);
          }).toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  /// Entretiens ayant une date de prochain rappel (`nextDueDate`).
  Future<List<Maintenance>> fetchMaintenancesWithNextDue(
    String vehicleId,
  ) async {
    final snapshot = await _firestore
        .collection('maintenances')
        .where('vehicleId', isEqualTo: vehicleId)
        .get();

    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Maintenance.fromMap(data);
        })
        .where(
          (m) =>
              m.nextDueDate != null ||
              m.items.any((i) => i.nextDueDate != null),
        )
        .toList();
  }

  // ✅ Lire les maintenances d'un véhicule (triées par date DESC)
  Stream<List<Maintenance>> watchMaintenances(
    String vehicleId,
    String userId, {
    String? ownerId,
  }) {
    Query query = _firestore
        .collection('maintenances')
        .where('userId', isEqualTo: userId)
        .where('vehicleId', isEqualTo: vehicleId);

    if (ownerId != null) {
      query = query.where('ownerId', isEqualTo: ownerId);
    }

    return query.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.where((doc) => doc.data() != null).map((doc) {
        final data = doc.data() as Map<String, dynamic>;
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

  // ✅ Méthode pour les professionnels pour accéder aux maintenances de leurs clients
  Stream<List<Maintenance>> getProfessionalMaintenancesStream({
    required String professionalId,
    required String vehicleId,
    required String clientId,
  }) {
    return _firestore
        .collection('maintenances')
        .where('vehicleId', isEqualTo: vehicleId)
        .where('ownerId', isEqualTo: clientId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Maintenance.fromMap(
              data,
            ); // Utilisation de fromMap au lieu de fromFirestore
          }).toList(),
        );
  }

  // ✅ CORRIGÉ: Méthode pour les pros
  Stream<List<Maintenance>> getProfessionalMaintenances({
    required String vehicleId,
    required String clientId,
  }) {
    return _firestore
        .collection('maintenances')
        .where('vehicleId', isEqualTo: vehicleId)
        .where(
          'ownerId',
          isEqualTo: clientId,
        ) // ⚠️ CHANGÉ: 'userId' au lieu de 'ownerId'
        .orderBy('date', descending: true)
        .snapshots()
        .handleError((error) {
          throw error;
        })
        .map((snapshot) {
          final maintenances = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Maintenance.fromMap(data);
          }).toList();

          return maintenances;
        });
  }

  // Dans MaintenanceService class
  Future<void> addMaintenanceForSharedVehicle({
    required Maintenance maintenance,
    required String currentUserId,
  }) async {
    // Vérifier que l'utilisateur a la permission d'ajouter
    final vehicleDoc = await _firestore
        .collection('vehicles')
        .doc(maintenance.vehicleId)
        .get();

    final vehicleData = vehicleDoc.data();
    if (vehicleData == null) throw Exception('Véhicule non trouvé');

    final vehicleOwnerId = vehicleData['ownerId'];

    // Si c'est le propriétaire
    if (vehicleOwnerId == currentUserId) {
      await addMaintenance(maintenance);
      return;
    }

    // Vérifier les permissions partagées
    final sharedList = List<Map<String, dynamic>>.from(
      vehicleData['sharedWith'] ?? [],
    );

    final userAccess = sharedList.firstWhere(
      (access) => access['userId'] == currentUserId,
      orElse: () => {},
    );

    final permissions = List<String>.from(userAccess['permissions'] ?? []);

    if (!permissions.contains('maintenance_add')) {
      throw Exception(
        'Vous n\'avez pas la permission d\'ajouter des maintenances',
      );
    }

    // ✅ CORRIGÉ : Créer une nouvelle maintenance avec copyWith
    final maintenanceToAdd = maintenance.copyWith(
      ownerId: vehicleOwnerId,
      userId: currentUserId, // L'utilisateur qui crée réellement la maintenance
    );

    await addMaintenance(maintenanceToAdd);
  }

  // Dans MaintenanceService class
  Future<void> addMaintenanceWithPermissionCheck({
    required Maintenance maintenance,
    required String currentUserId,
  }) async {
    // 1. Vérifier si l'utilisateur est propriétaire du véhicule
    final vehicleDoc = await _firestore
        .collection('vehicles')
        .doc(maintenance.vehicleId)
        .get();

    final vehicleData = vehicleDoc.data();
    if (vehicleData == null) {
      throw Exception('Véhicule non trouvé');
    }

    final vehicleOwnerId = vehicleData['ownerId'];

    // 2. Si c'est le propriétaire, ajouter directement
    if (vehicleOwnerId == currentUserId) {
      // S'assurer que ownerId et userId sont corrects
      final maintenanceWithOwner = maintenance.copyWith(
        ownerId: vehicleOwnerId,
        userId: currentUserId,
      );
      await addMaintenance(maintenanceWithOwner);
      return;
    }

    // 3. Sinon, vérifier les permissions partagées
    await addMaintenanceForSharedVehicle(
      maintenance: maintenance,
      currentUserId: currentUserId,
    );
  }
}
