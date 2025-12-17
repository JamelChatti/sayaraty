import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/attachment_service.dart';
import '../../application/vehicle_service.dart';
import '../screens/image_viewer_screen.dart';

class AttachmentSection extends ConsumerWidget {
  final String vehicleId;
  final List<String> initialAttachments;

  const AttachmentSection({
    super.key,
    required this.vehicleId,
    required this.initialAttachments,
  });

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
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;

  Future<void> _addAttachments() async {
    if (widget.attachments.length >= 7) {
      _snack('Maximum 7 pièces jointes');
      return;
    }

    final images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isEmpty) return;

    setState(() => _loading = true);

    final newUrls = <String>[];

    for (final img in images) {
      if (widget.attachments.length + newUrls.length >= 7) break;

      final file = File(img.path);
      final url = await ref
          .read(attachmentServiceProvider)
          .uploadAttachment(widget.vehicleId, file);

      newUrls.add(url);
    }

    await ref.read(vehicleServiceProvider).updateVehicleAttachments(
      widget.vehicleId,
      [...widget.attachments, ...newUrls],
    );

    setState(() => _loading = false);
  }

  Future<void> _removeAttachment(String url) async {
    await ref.read(attachmentServiceProvider).deleteAttachment(url);

    await ref.read(vehicleServiceProvider).updateVehicleAttachments(
      widget.vehicleId,
      widget.attachments.where((e) => e != url).toList(),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pièces jointes (${widget.attachments.length}/7)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (_loading) const LinearProgressIndicator(),

          if (widget.attachments.isEmpty && !_loading)
            const Text(
              'Aucune pièce jointe',
              style: TextStyle(color: Colors.grey),
            ),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.attachments.map((url) {
              return Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ImageViewerScreen(imageUrl: url),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
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
            label: const Text('Ajouter des pièces jointes'),
          ),
        ],
      ),
    );
  }
}
