import 'dart:io';
import 'package:flutter/material.dart';
import 'package:finalltmcb/Model/ChatMessage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:finalltmcb/Widget/FilePickerUtil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:path/path.dart' as path;

typedef MessageCallback = void Function(ChatMessage message);
typedef ProcessingCallback = void Function();
typedef ErrorCallback = void Function(String message,
    {bool isError, bool isSuccess, bool isInfo, Duration? duration});

class MediaHandlerWidget {
  final BuildContext context;
  final MessageCallback onMessageCreated;
  final String userId;
  final ProcessingCallback onProcessingStart;
  final ProcessingCallback onProcessingEnd;
  final ErrorCallback onError;

  MediaHandlerWidget({
    required this.context,
    required this.onMessageCreated,
    required this.userId,
    required this.onProcessingStart,
    required this.onProcessingEnd,
    required this.onError,
  });

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

  Future<void> handleVideoSend() async {
    print("Video send button clicked");
    onProcessingStart();

    try {
      // Pick video using image_picker
      final ImagePicker picker = ImagePicker();

      onError("Đang mở chọn video...",
          isInfo: true, duration: Duration(seconds: 1));

      final XFile? pickedVideo = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );

      if (pickedVideo == null) {
        print("No video selected");
        onProcessingEnd();
        return;
      }

      print("Selected video: ${pickedVideo.path}");

      Uint8List? videoBytes;
      FileMessage? videoFileMessage;
      if (!kIsWeb && pickedVideo.path != null) {
        final File videoFile = File(pickedVideo.path!);
        videoBytes = await videoFile.readAsBytes();
        print("Video file bytes read: ${videoBytes.length} bytes");
        videoFileMessage = FileMessage(
          fileName: path.basename(pickedVideo.path),
          mimeType: 'video', // Corrected mimeType to 'video'
          fileSize: videoBytes.length,
          filePath: pickedVideo.path,
          fileBytes: videoBytes,
        );
      }

      // Create message with video file message
      final message = ChatMessage(
        text: '',
        isMe: true,
        timestamp: DateTime.now(),
        videoFile: videoFileMessage, // Use videoFileMessage here
        isVideoLoading: false,
      );

      // Send message
      onMessageCreated(message);
      onProcessingEnd();
    } catch (e) {
      // Added catch block body
      print("Error handling video: $e");
      onError("Lỗi chọn video: ${e.toString().split('\n').first}",
          isError: true);
      onProcessingEnd();
    }
  }
}
