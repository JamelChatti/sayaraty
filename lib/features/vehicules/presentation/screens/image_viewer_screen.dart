import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;

  const ImageViewerScreen({
    super.key,
    required this.imageUrl,
  });

  Future<void> _shareImage(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/image.jpg');
      await file.writeAsBytes(response.bodyBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Image véhicule - Sayaraty',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors du partage')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareImage(context),
          ),
        ],
      ),
      body: PhotoView(
        imageProvider: NetworkImage(imageUrl),
        backgroundDecoration:
        const BoxDecoration(color: Colors.black),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
      ),
    );
  }
}
