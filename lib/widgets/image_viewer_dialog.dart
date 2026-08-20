import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Modal d'aperçu d'image plein écran avec zoom interactif
class ImageViewerDialog extends StatelessWidget {
  const ImageViewerDialog({
    super.key,
    required this.imagePathOrUrl,
    this.title = 'Photo',
  });

  final String imagePathOrUrl;
  final String title;

  static void show(BuildContext context, {required String imagePathOrUrl, String title = 'Photo'}) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => ImageViewerDialog(
        imagePathOrUrl: imagePathOrUrl,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNetwork = kIsWeb ||
        imagePathOrUrl.startsWith('http://') ||
        imagePathOrUrl.startsWith('https://') ||
        imagePathOrUrl.startsWith('data:') ||
        imagePathOrUrl.startsWith('blob:');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Image zoomable
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: isNetwork
                  ? Image.network(
                      imagePathOrUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
                      ),
                    )
                  : Image.file(
                      File(imagePathOrUrl),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
                      ),
                    ),
            ),
          ),

          // Header avec bouton fermer
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
