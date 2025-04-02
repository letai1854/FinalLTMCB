import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerHandler {
  // Instance of ImagePicker
  final ImagePicker _picker = ImagePicker();

  // Pick multiple images from gallery
  Future<List<XFile>?> pickMultipleImages() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage();
      return images;
    } catch (e) {
      print("Error picking images: $e");
      return null;
    }
  }

  // Process a single image to base64
  Future<String?> processImageToBase64(XFile image) async {
    try {
      String base64Image;

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        base64Image = base64Encode(bytes);
      } else {
        File imageFile = File(image.path);
        final bytes = await imageFile.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      if (base64Image.isNotEmpty) {
        print(
            'Base64 image (first 50 chars): ${base64Image.substring(0, math.min(50, base64Image.length))}...');
        return base64Image;
      }
      return null;
    } catch (e) {
      print("Error processing image to base64: $e");
      return null;
    }
  }

  // Get image widget from XFile (for preview)
  Widget getImageWidget(XFile image,
      {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (kIsWeb) {
      return Image.network(
        image.path,
        width: width,
        height: height,
        fit: fit,
      );
    } else {
      return Image.file(
        File(image.path),
        width: width,
        height: height,
        fit: fit,
      );
    }
  }
}
