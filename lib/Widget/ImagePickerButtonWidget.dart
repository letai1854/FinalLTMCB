import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:finalltmcb/Widget/ImagePickerHandler.dart';

class ImagePickerButtonWidget extends StatefulWidget {
  /// Callback that provides the list of selected images to the parent
  final Function(List<XFile>) onImagesSelected;

  /// Optional custom icon color
  final Color iconColor;

  /// Optional custom icon size
  final double iconSize;

  const ImagePickerButtonWidget({
    Key? key,
    required this.onImagesSelected,
    this.iconColor = Colors.red,
    this.iconSize = 24.0,
  }) : super(key: key);

  @override
  State<ImagePickerButtonWidget> createState() =>
      _ImagePickerButtonWidgetState();
}

class _ImagePickerButtonWidgetState extends State<ImagePickerButtonWidget> {
  final ImagePickerHandler _imagePickerHandler = ImagePickerHandler();
  bool _isPickingImages = false;

  Future<void> _pickImage() async {
    // Prevent multiple simultaneous picking operations
    if (_isPickingImages) return;

    try {
      // Don't set loading state here - we'll keep showing the image icon
      // during the native picker dialog

      final List<XFile>? images =
          await _imagePickerHandler.pickMultipleImages();

      if (images != null && images.isNotEmpty) {
        // Only set loading state if we're processing the images after selection
        // setState(() => _isPickingImages = true);

        // Pass the selected images to the parent
        widget.onImagesSelected(images);

        // Reset loading state if needed
        // if (mounted) setState(() => _isPickingImages = false);
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always show the image icon, regardless of loading state
    return IconButton(
      onPressed: _pickImage,
      icon: Icon(
        Icons.image,
        color: widget.iconColor,
        size: widget.iconSize,
      ),
    );
  }
}
