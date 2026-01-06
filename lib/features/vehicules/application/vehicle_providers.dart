import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/vehicule_model.dart';
import 'attachment_service.dart';
import 'vehicle_service.dart';

final vehiclesStreamProvider =
StreamProvider.family<List<Vehicle>, String>((ref, userId) {
  final service = ref.read(vehicleServiceProvider);
  return service.watchUserVehicles(userId);
});

final attachmentServiceProvider =
Provider<AttachmentService>((ref) => AttachmentService());


final sharedVehiclesStreamProvider = StreamProvider.autoDispose
    .family<List<Vehicle>, String>((ref, userId) {

  return FirebaseFirestore.instance
      .collection('vehicles')
      .snapshots()
      .asyncMap((snapshot) async {
    final vehicles = <Vehicle>[];

    for (final doc in snapshot.docs) {
      try {
        final data = doc.data() ;

        // Vérifier si l'utilisateur est propriétaire
        final ownerId = data['ownerId'] as String?;
        if (ownerId == userId) {
          vehicles.add(Vehicle.fromMap(data, doc.id));
          continue;
        }

        // Vérifier les accès partagés
        final sharedWithRaw = data['sharedWith'];
        if (sharedWithRaw is List && sharedWithRaw.isNotEmpty) {
          bool hasAccess = false;

          // Vérification rapide sans parsing complet
          for (final item in sharedWithRaw) {
            if (item is Map<String, dynamic>) {
              if (item['userId'] == userId) {
                hasAccess = true;
                break;
              }
            }
          }

          if (hasAccess) {
            vehicles.add(Vehicle.fromMap(data, doc.id));
          }
        }
      } catch (e) {
        print('❌ Erreur traitement véhicule ${doc.id}: $e');
      }
    }

    return vehicles;
  });
});

// Provider pour les véhicules PARTAGÉS AVEC l'utilisateur (exclut les propres)
final vehiclesSharedWithMeProvider = StreamProvider.autoDispose
    .family<List<Vehicle>, String>((ref, userId) {

  return FirebaseFirestore.instance
      .collection('vehicles')
      .snapshots()
      .asyncMap((snapshot) async {
    final vehicles = <Vehicle>[];

    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();

        // ⚠️ EXCLURE les véhicules dont l'utilisateur est propriétaire
        final ownerId = data['ownerId'] as String?;
        if (ownerId == userId) {
          continue; // On saute complètement les véhicules personnels
        }

        // Vérifier si l'utilisateur a un accès partagé
        final sharedWithRaw = data['sharedWith'];
        if (sharedWithRaw is List && sharedWithRaw.isNotEmpty) {
          bool hasAccess = false;

          for (final item in sharedWithRaw) {
            if (item is Map<String, dynamic>) {
              if (item['userId'] == userId) {
                hasAccess = true;
                break;
              }
            }
          }

          if (hasAccess) {
            vehicles.add(Vehicle.fromMap(data, doc.id));
          }
        }
      } catch (e) {
        print('❌ Erreur traitement véhicule ${doc.id}: $e');
      }
    }

    return vehicles;
  });
});