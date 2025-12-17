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
