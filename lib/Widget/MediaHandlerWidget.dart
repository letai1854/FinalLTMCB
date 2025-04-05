import 'dart:io';
import 'dart:convert'; // Add for base64Encode
import 'package:flutter/material.dart';
import 'package:finalltmcb/Model/ChatMessage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:finalltmcb/Widget/FilePickerUtil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:finalltmcb/Model/VideoFileMessage.dart'; // Import VideoFileMessage
import 'package:mime/mime.dart'; // Import for lookupMimeType

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

      // Ensure we have bytes
       Uint8List? fileBytes = file.bytes;
        if (fileBytes == null && file.path != null && !kIsWeb) {
            try {
                fileBytes = await File(file.path!).readAsBytes();
            } catch (e) {
                print("Error reading file bytes from path: $e");
                onError('Error reading file data', isError: true);
                onProcessingEnd();
                return;
            }
        }

       if (fileBytes == null) {
            print("File bytes are null.");
             onError('Could not load file data', isError: true);
             onProcessingEnd();
             return;
        }

      // Create file message from result
      final fileMessage = FileMessage(
        fileName: file.name,
        mimeType: lookupMimeType(file.name, headerBytes: fileBytes.take(1024).toList()) ?? FilePickerUtil.getMimeType(file.name),
        fileSize: fileBytes.length,
        filePath: file.path ?? '',
        fileBytes: fileBytes,
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

    } catch (e) {
      print("Error handling file: $e");
      onError('Không thể chọn file: ${e.toString().split('\n').first}');
    } finally {
       onProcessingEnd();
    }
  }

  Future<void> handleVideoSend() async {
    print("Video send button clicked");
    onProcessingStart();

    try {
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

      print("Selected video path: ${pickedVideo.path}");

      Uint8List videoBytes;
      String videoPath = pickedVideo.path; // Store path for local playback if needed
      String videoName = path.basename(videoPath);

      if (kIsWeb) {
        videoBytes = await pickedVideo.readAsBytes();
        print("Web video bytes read: ${videoBytes.length} bytes");
      } else {
        final File videoFile = File(videoPath);
        videoBytes = await videoFile.readAsBytes();
        print("Native video file bytes read: ${videoBytes.length} bytes");
      }

      String mimeType = lookupMimeType(videoName, headerBytes: videoBytes.take(1024).toList()) ?? 'video/mp4';
      print("Detected video MIME type: $mimeType");

      // Create VideoFileMessage
      final videoFileMessage = VideoFileMessage(
        fileName: videoName,
        mimeType: mimeType,
        fileSize: videoBytes.length,
        base64Data: base64Encode(videoBytes), // Encode bytes to base64
        localPath: videoPath, // Store local path
        // duration: // TODO: Implement video duration extraction if needed
        // thumbnail: // TODO: Implement thumbnail generation if needed
      );

      print("VideoFileMessage created: ${videoFileMessage.fileName}, size: ${videoFileMessage.readableSize}");

      // Create ChatMessage with VideoFileMessage
      final message = ChatMessage(
        text: '',
        isMe: true,
        timestamp: DateTime.now(),
        video: videoFileMessage, // Use the 'video' field
        isVideoLoading: false,
      );

      onMessageCreated(message);

    } catch (e) {
      print("Error handling video: $e");
      onError("Lỗi chọn video: ${e.toString().split('\n').first}",
          isError: true);
    } finally {
      onProcessingEnd();
    }
  }
}
