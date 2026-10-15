import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/security/password_confirm_dialog.dart';
import '../../application/attachment_service.dart';
import '../../application/vehicle_service.dart';
import '../screens/full_screen_image.dart';

class AttachmentSection extends ConsumerWidget {
  final String vehicleId;

  const AttachmentSection({
    super.key,
    required this.vehicleId,
  });

  static const int maxFiles = 13;
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

        return _AttachmentContent(
          vehicleId: vehicleId,
          attachments: vehicle.attachments,
          mainPhotoUrl: vehicle.mainPhotoUrl,
        );
      },
    );
  }
}

class _AttachmentContent extends ConsumerStatefulWidget {
  final String vehicleId;
  final List<String> attachments;
  final String? mainPhotoUrl;

  const _AttachmentContent({
    required this.vehicleId,
    required this.attachments,
    required this.mainPhotoUrl,
  });

  @override
  ConsumerState<_AttachmentContent> createState() =>
      _AttachmentContentState();
}

class _AttachmentContentState extends ConsumerState<_AttachmentContent> {
  bool _loading = false;
  final _imagePicker = ImagePicker();

  Future<void> _showAddOptions() async {
    if (widget.attachments.length >= AttachmentSection.maxFiles) {
      _snack('Maximum ${AttachmentSection.maxFiles} fichiers');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Photo'),
              subtitle: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(ctx);
                _addFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              subtitle: const Text('Choisir une ou plusieurs photos'),
              onTap: () {
                Navigator.pop(ctx);
                _addFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: const Text('Scanner'),
              subtitle: const Text(
                'Détection des bords, recadrage et filtres',
              ),
              onTap: () {
                Navigator.pop(ctx);
                _addFromScanner();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Fichier'),
              subtitle: const Text('Image ou PDF'),
              onTap: () {
                Navigator.pop(ctx);
                _addFromFiles();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _addFromCamera() async {
    try {
      final shot = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (shot == null) return;
      await _uploadLocalFiles([File(shot.path)]);
    } catch (_) {
      _snack('Impossible d’ouvrir l’appareil photo');
    }
  }

  Future<void> _addFromGallery() async {
    try {
      final images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (images.isEmpty) return;
      await _uploadLocalFiles(images.map((e) => File(e.path)).toList());
    } catch (_) {
      _snack('Impossible d’ouvrir la galerie');
    }
  }

  Future<void> _addFromScanner() async {
    if (!Platform.isAndroid) {
      _snack('Le scanner de documents est disponible uniquement sur Android');
      return;
    }

    final remaining = AttachmentSection.maxFiles - widget.attachments.length;
    if (remaining <= 0) {
      _snack('Maximum ${AttachmentSection.maxFiles} fichiers');
      return;
    }

    final documentScanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormats: const {DocumentFormat.jpeg},
        mode: ScannerMode.full,
        pageLimit: remaining.clamp(1, AttachmentSection.maxFiles),
        isGalleryImport: false,
      ),
    );

    try {
      final result = await documentScanner.scanDocument();
      final imagePaths = result.images ?? const <String>[];
      if (imagePaths.isEmpty) return;

      final files = <File>[];
      for (final rawPath in imagePaths) {
        final file = _fileFromScannerPath(rawPath);
        if (file != null && await file.exists()) {
          files.add(file);
        }
      }

      if (files.isEmpty) {
        _snack('Aucun document scanné');
        return;
      }

      await _uploadLocalFiles(files);
    } on PlatformException catch (e) {
      final cancelled = e.code.toLowerCase().contains('cancel');
      if (!cancelled) {
        _snack('Impossible d’ouvrir le scanner de documents');
      }
    } catch (_) {
      _snack('Impossible d’ouvrir le scanner de documents');
    } finally {
      await documentScanner.close();
    }
  }

  File? _fileFromScannerPath(String rawPath) {
    final trimmed = rawPath.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('file://')) {
      return File(Uri.parse(trimmed).toFilePath(windows: false));
    }
    return File(trimmed);
  }

  Future<void> _addFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );
    if (result == null) return;

    final files = <File>[];
    for (final file in result.files) {
      if (file.path == null) continue;
      if (file.size > AttachmentSection.maxFileSize) {
        _snack('Le fichier ${file.name} dépasse 10 MB et a été ignoré');
        continue;
      }
      files.add(File(file.path!));
    }
    if (files.isEmpty) return;
    await _uploadLocalFiles(files);
  }

  Future<void> _uploadLocalFiles(List<File> files) async {
    setState(() => _loading = true);
    final newUrls = <String>[];

    try {
      for (final file in files) {
        if (widget.attachments.length + newUrls.length >=
            AttachmentSection.maxFiles) {
          break;
        }

        final size = await file.length();
        if (size > AttachmentSection.maxFileSize) {
          _snack(
            'Le fichier ${file.uri.pathSegments.last} dépasse 10 MB '
            'et a été ignoré',
          );
          continue;
        }

        final url = await ref
            .read(attachmentServiceProvider)
            .uploadAttachment(widget.vehicleId, file);
        newUrls.add(url);
      }

      if (newUrls.isNotEmpty) {
        await ref.read(vehicleServiceProvider).updateVehicleAttachments(
              widget.vehicleId,
              [...widget.attachments, ...newUrls],
            );
      }
    } catch (_) {
      _snack('Échec de l’envoi du document');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeAttachment(String url) async {
    try {
      await ref.read(attachmentServiceProvider).deleteAttachment(url);
    } catch (_) {
      // Continuer même si le fichier Storage a déjà disparu
    }

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _norm(String url) => url.trim().toLowerCase();

  bool _isImage(String url) {
    final u = _norm(url);
    return u.contains('.jpg') ||
        u.contains('.jpeg') ||
        u.contains('.png') ||
        u.contains('.webp');
  }

  bool _isPdf(String url) {
    final u = _norm(url);
    return u.contains('.pdf');
  }

  Future<void> _confirmDeleteAttachment(String url) async {
    final isImage = _isImage(url);
    final isPdf = _isPdf(url);
    String fileType = 'fichier';

    if (isImage) {
      fileType = 'image';
    } else if (isPdf) {
      fileType = 'PDF';
    }

    final confirmed = await confirmWithPassword(
      context,
      title: 'Confirmer la suppression',
      message:
          'Êtes-vous sûr de vouloir supprimer ce $fileType ? '
          'Cette action est irréversible.\n'
          'Entrez votre mot de passe pour confirmer.',
      confirmLabel: 'Supprimer',
      isDestructive: true,
    );

    if (confirmed == true) {
      await _removeAttachment(url);
    }
  }

  Future<void> _confirmSetMainPhoto(String url) async {
    if (!_isImage(url)) {
      _snack('Seule une image peut être photo principale');
      return;
    }
    if (url == widget.mainPhotoUrl) {
      _snack('Cette photo est déjà la photo principale');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Photo principale'),
        content: const Text(
          'Définir cette photo comme photo principale du véhicule ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(vehicleServiceProvider)
          .updateMainPhoto(widget.vehicleId, url);
      if (!mounted) return;
      _snack('Photo principale mise à jour');
    } catch (e) {
      if (!mounted) return;
      _snack('Erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pièces jointes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pièces jointes (${widget.attachments.length}/${AttachmentSection.maxFiles})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Appui long sur une photo pour la définir en principale',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.attachments.map((url) {
                final isMain = url == widget.mainPhotoUrl;
                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_isImage(url)) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullScreenImage(imageUrl: url),
                            ),
                          );
                        } else if (_isPdf(url)) {
                          _openPdf(url);
                        } else {
                          _snack('Extension non détectée');
                        }
                      },
                      onLongPress: _isImage(url)
                          ? () => _confirmSetMainPhoto(url)
                          : null,
                      child: Stack(
                        children: [
                          _buildPreview(url),
                          if (isMain)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => _confirmDeleteAttachment(url),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loading ? null : _showAddOptions,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une pièce jointe'),
            ),
          ],
        ),
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
        child: const Icon(Icons.picture_as_pdf, size: 40, color: Colors.red),
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
