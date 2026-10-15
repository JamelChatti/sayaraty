import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

final attachmentServiceProvider = Provider<AttachmentService>((ref) {
  return AttachmentService();
});

class AttachmentService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload un fichier sous `vehicles/{vehicleId}/...` et retourne son URL.
  Future<String> uploadAttachment(String vehicleId, File file) {
    return uploadFile(
      storageFolder: 'vehicles',
      parentId: vehicleId,
      file: file,
    );
  }

  /// Upload un fichier sous `maintenances/{maintenanceId}/...` et retourne son URL.
  Future<String> uploadMaintenanceAttachment(
    String maintenanceId,
    File file,
  ) {
    return uploadFile(
      storageFolder: 'maintenances',
      parentId: maintenanceId,
      file: file,
    );
  }

  Future<String> uploadFile({
    required String storageFolder,
    required String parentId,
    required File file,
  }) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';

    final ref = _storage
        .ref()
        .child(storageFolder)
        .child(parentId)
        .child(fileName);

    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  /// Supprime un fichier à partir de son URL
  Future<void> deleteAttachment(String url) async {
    final ref = _storage.refFromURL(url);
    await ref.delete();
  }
}
