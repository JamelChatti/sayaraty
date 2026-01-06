import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({
    super.key,
    required this.imageUrl,
  });

  bool _isPdf(String url) =>
      url.toLowerCase().contains('.pdf');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              await Share.share(
                imageUrl,
                subject: _isPdf(imageUrl)
                    ? 'Document PDF'
                    : 'Image véhicule',
              );
            },
          ),
        ],
      ),

      body: Center(
        child: Hero(
          tag: imageUrl,
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: _isPdf(imageUrl)
                ? const Icon(
              Icons.picture_as_pdf,
              color: Colors.white,
              size: 120,
            )
                : Image.network(
              imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
