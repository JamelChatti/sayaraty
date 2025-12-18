import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/attachment_service.dart';
import '../../application/vehicle_service.dart';
import '../screens/full_screen_image.dart';

class AttachmentSection extends ConsumerWidget {
  final String vehicleId;

  const AttachmentSection({
    super.key,
    required this.vehicleId,
  });

  static const int maxFiles = 7;
  static const int maxFileSize = 10 * 1024 * 1024; // ✅ 10 MB

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync = ref.watch(vehicleByIdStreamProvider(vehicleId));

    return vehicleAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Erreur: $e'),
      data: (vehicle) {
        if (vehicle == null) {
          return const Text('Véhicule introuvable');
        }

        final attachments = vehicle.attachments;

        return _AttachmentContent(
          vehicleId: vehicleId,
          attachments: attachments,
        );
      },
    );
  }
}

class _AttachmentContent extends ConsumerStatefulWidget {
  final String vehicleId;
  final List<String> attachments;

  const _AttachmentContent({
    required this.vehicleId,
    required this.attachments,
  });

  @override
  ConsumerState<_AttachmentContent> createState() =>
      _AttachmentContentState();
}

class _AttachmentContentState
    extends ConsumerState<_AttachmentContent> {
  bool _loading = false;

  // ----------------------------
  // ADD MULTIPLE WITH SIZE CHECK
  // ----------------------------
  Future<void> _addAttachments() async {
    if (widget.attachments.length >= AttachmentSection.maxFiles) {
      _snack('Maximum ${AttachmentSection.maxFiles} fichiers');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],

    );

    if (result == null) return;

    setState(() => _loading = true);
    final newUrls = <String>[];

    for (final file in result.files) {
      if (widget.attachments.length + newUrls.length >=
          AttachmentSection.maxFiles) break;

      if (file.size > AttachmentSection.maxFileSize) {
        _snack(
            'Le fichier ${file.name} dépasse 10 MB et a été ignoré');
        continue;
      }

      final localFile = File(file.path!);

      final url = await ref
          .read(attachmentServiceProvider)
          .uploadAttachment(widget.vehicleId, localFile);

      newUrls.add(url);
    }

    if (newUrls.isNotEmpty) {
      await ref.read(vehicleServiceProvider).updateVehicleAttachments(
        widget.vehicleId,
        [...widget.attachments, ...newUrls],
      );
    }

    setState(() => _loading = false);
  }

  // ----------------------------
  // DELETE
  // ----------------------------
  Future<void> _removeAttachment(String url) async {
    await ref.read(attachmentServiceProvider).deleteAttachment(url);

    await ref.read(vehicleServiceProvider).updateVehicleAttachments(
      widget.vehicleId,
      widget.attachments.where((e) => e != url).toList(),
    );
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);

    if (!await canLaunchUrl(uri)) {
      _snack('Impossible d’ouvrir le PDF');
      return;
    }

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String _norm(String url) => url.trim().toLowerCase();

  bool _isImage(String url) {
    final u = _norm(url);
    return u.contains('.jpg') || u.contains('.jpeg') || u.contains('.png') || u.contains('.webp');
  }

  bool _isPdf(String url) {
    final u = _norm(url);
    return u.contains('.pdf');
  }



  // ----------------------------
  // UI
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pièces jointes (${widget.attachments.length}/${AttachmentSection.maxFiles})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (_loading) const LinearProgressIndicator(),

          // if (widget.attachments.isEmpty && !_loading)
          //   const Text(
          //     'Aucune pièce jointe',
          //     style: TextStyle(color: Colors.grey),
          //   ),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.attachments.map((url) {
              return Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      debugPrint('URL = "$url"');
                      debugPrint('_isImage=${_isImage(url)}  _isPdf=${_isPdf(url)}');

                      if (_isImage(url)) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImage(imageUrl: url)));
                      } else if (_isPdf(url)) {
                        _openPdf(url);
                      } else {
                        _snack('Extension non détectée');
                      }
                    },

                    child: _buildPreview(url),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => _removeAttachment(url),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _loading ? null : _addAttachments,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter des fichiers'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(String url) {
    if (_isImage(url)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 90,
          height: 90,
          fit: BoxFit.cover,
        ),
      );
    } else if (_isPdf(url)) {
      return Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child:
        const Icon(Icons.picture_as_pdf, size: 40, color: Colors.red),
      );
    }
    return Container(
      width: 90,
      height: 90,
      color: Colors.grey.shade200,
      child: const Icon(Icons.insert_drive_file),
    );
  }
}
