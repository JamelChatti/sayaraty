import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

final attachmentServiceProvider = Provider<AttachmentService>((ref) {
  return AttachmentService();
});

class AttachmentService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload un fichier et retourne son URL
  Future<String> uploadAttachment(String vehicleId, File file) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';

    final ref = _storage
        .ref()
        .child('vehicles')
        .child(vehicleId)
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
