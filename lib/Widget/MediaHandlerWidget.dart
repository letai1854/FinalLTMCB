import 'dart:io';
import 'package:flutter/material.dart';
import 'package:finalltmcb/Model/ChatMessage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:finalltmcb/Widget/FilePickerUtil.dart';
import 'package:image_picker/image_picker.dart';
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

      // Verify video file exists and has content
      if (!kIsWeb) {
        try {
          final File videoFile = File(pickedVideo.path);
          if (!await videoFile.exists()) {
            onError("Không thể truy cập file video", isError: true);
            onProcessingEnd();
            return;
          }

          final size = await videoFile.length();
          print("Video file size: $size bytes");

          if (size == 0) {
            onError("Không thể gửi video rỗng", isError: true);
            onProcessingEnd();
            return;
          }

          // Check Windows compatibility
          if (Platform.isWindows) {
            final extension = path.extension(pickedVideo.path).toLowerCase();
            if (!['.mp4', '.webm'].contains(extension)) {
              onError(
                  "Windows chỉ hỗ trợ video định dạng MP4 và WebM, định dạng hiện tại: $extension",
                  isError: true,
                  duration: Duration(seconds: 5));
              // Continue anyway to let VideoBubble handle the error display
            }
          }
        } catch (e) {
          print("Error checking video file: $e");
        }
      }

      // Create message with direct path - no need to save to app directory
      final message = ChatMessage(
        text: '',
        isMe: true,
        timestamp: DateTime.now(),
        video: pickedVideo.path,
        isVideoLoading: false, // No loading state needed
      );

      // Send message
      onMessageCreated(message);
      onProcessingEnd();
    } catch (e) {
      print("Error handling video: $e");
      onError("Lỗi chọn video: ${e.toString().split('\n').first}",
          isError: true);
      onProcessingEnd();
    }
  }
}
