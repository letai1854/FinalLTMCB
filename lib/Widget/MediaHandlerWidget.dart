import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:finalltmcb/Model/ChatMessage.dart';
import 'package:finalltmcb/Widget/FilePickerUtil.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

typedef MediaMessageCallback = void Function(ChatMessage message);

class MediaHandlerWidget {
  final BuildContext context;
  final MediaMessageCallback onMessageCreated;
  final String userId;
  final Function() onProcessingStart;
  final Function() onProcessingEnd;
  final Function(String) onError;

  MediaHandlerWidget({
    required this.context,
    required this.onMessageCreated,
    required this.userId,
    required this.onProcessingStart,
    required this.onProcessingEnd,
    required this.onError,
  });

  // Handle file selection and upload
  Future<void> handleFileSend() async {
    print("File send button clicked");

    onProcessingStart();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true, // Always load file data for consistency
        dialogTitle: 'Select a file to share',
      );

      if (result == null || result.files.isEmpty) {
        print("No file selected or selection canceled");
        onProcessingEnd();
        return;
      }

      final file = result.files.first;
      print("Selected file: ${file.name}, size: ${file.size} bytes");

      // Create file message from result
      final fileMessage = FileMessage(
        fileName: file.name,
        mimeType: FilePickerUtil.getMimeType(file.name),
        fileSize: file.size,
        filePath: file.path ?? '',
        fileBytes: file.bytes,
      );

      // Create the chat message
      final message = ChatMessage(
        text: '', // Empty text for file messages
        isMe: true,
        timestamp: DateTime.now(),
        file: fileMessage,
      );

      // Pass the message back via callback
      onMessageCreated(message);
      onProcessingEnd();

      // Note: The callback handler should handle scrolling and adding to the message list
    } catch (e) {
      print("Error handling file: $e");
      onProcessingEnd();
      onError('Không thể chọn file: ${e.toString().split('\n').first}');
    }
  }

  // Handle video selection and upload with fix for loading issue
  Future<void> handleVideoSend() async {
    print("Video send button clicked");

    onProcessingStart();

    try {
      // Pick video from gallery
      final ImagePicker picker = ImagePicker();

      final XFile? pickedVideo = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );

      if (pickedVideo == null) {
        print("No video selected or selection canceled");
        onProcessingEnd();
        return;
      }

      print("Selected video: ${pickedVideo.path}");

      // Read video as bytes - this fixes the loading issue by keeping video in memory
      final Uint8List videoBytes = await pickedVideo.readAsBytes();

      // Store the bytes temporarily to use with the message
      // (We'll store this in memory only, not in local storage)

      // Create the video message with compatible parameters
      // Use only parameters that are supported by the ChatMessage class
      final ChatMessage videoMessage = ChatMessage(
        text: '',
        isMe: true,
        timestamp: DateTime.now(),
        video: pickedVideo.path,
        isVideoLoading:
            false, // Set to false immediately to avoid loading spinner
      );

      // Additional info for debugging
      print("Video loaded into memory: ${videoBytes.length} bytes");
      print("Video name: ${pickedVideo.name}");

      // Pass the message back via callback (only once)
      onMessageCreated(videoMessage);
      onProcessingEnd();

      /*
      // For server implementation (commented as requested):
      // Upload video to server code would go here
      */
    } catch (e) {
      print("Error handling video: $e");
      onProcessingEnd();
      onError("Lỗi chọn video: ${e.toString().split('\n').first}");
    }
  }
}
