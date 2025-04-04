import 'package:flutter/material.dart';
import 'package:finalltmcb/Widget/FullScreenImageViewer.dart';

class ImageViewerWidget {
  /// Static method to view an image in full screen
  static void viewImage(BuildContext context, String base64Image) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          base64Image: base64Image,
        ),
      ),
    );
  }
}
