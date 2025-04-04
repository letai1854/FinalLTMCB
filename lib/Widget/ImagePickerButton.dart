import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'ImagePickerHandler.dart';

class ImagePickerButton extends StatefulWidget {
  final Function(List<XFile>) onImagesSelected;

  const ImagePickerButton({Key? key, required this.onImagesSelected})
      : super(key: key);

  @override
  _ImagePickerButtonState createState() => _ImagePickerButtonState();
}

class _ImagePickerButtonState extends State<ImagePickerButton> {
  final ImagePickerHandler _imagePickerHandler = ImagePickerHandler();

  Future<void> _pickImage() async {
    try {
      final List<XFile>? images =
          await _imagePickerHandler.pickMultipleImages();

      if (images != null && images.isNotEmpty) {
        widget.onImagesSelected(images);
      }
    } catch (e) {
      print("Error picking image: $e");
      print('Failed to pick image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _pickImage,
      icon: const Icon(
        Icons.image,
        color: Colors.red,
      ),
    );
  }
}
