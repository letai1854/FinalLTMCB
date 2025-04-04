import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagesPreviewWidget extends StatelessWidget {
  final List<XFile> images;
  final Function(int) onRemove;
  final double height;
  final double imageSize;
  final EdgeInsets padding;

  const ImagesPreviewWidget({
    Key? key,
    required this.images,
    required this.onRemove,
    this.height = 90.0,
    this.imageSize = 70.0,
    this.padding = const EdgeInsets.only(right: 8.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: images.isEmpty ? 0 : height,
      margin: EdgeInsets.only(bottom: images.isEmpty ? 0 : 8.0),
      child: images.isEmpty
          ? const SizedBox.shrink()
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) =>
                  _buildImagePreview(context, index),
            ),
    );
  }

  Widget _buildImagePreview(BuildContext context, int index) {
    return Padding(
      padding: padding,
      child: Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Pre-sized container to avoid layout shifts
            Container(
              color: Colors.grey.shade100,
              width: imageSize,
              height: imageSize,
            ),
            // Image
            kIsWeb
                ? Image.network(
                    images[index].path,
                    fit: BoxFit.cover,
                    width: imageSize,
                    height: imageSize,
                  )
                : Image.file(
                    File(images[index].path),
                    fit: BoxFit.cover,
                    width: imageSize,
                    height: imageSize,
                  ),
            // Close button
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => onRemove(index),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
