import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data'; // Import typed_data

import 'package:file_picker/file_picker.dart';
import 'package:finalltmcb/Controllers/MessageController.dart'; // Import MessageController
import 'package:finalltmcb/Model/AudioMessage.dart';
import 'package:finalltmcb/Model/ChatMessage.dart';
import 'package:finalltmcb/Model/ImageMessage.dart';
import 'package:finalltmcb/Model/MessageData.dart';
import 'package:finalltmcb/Model/VideoFileMessage.dart';
import 'package:finalltmcb/Widget/AttachmentMenuWidget.dart';
import 'package:finalltmcb/Widget/AudioHandlerWidget.dart';
import 'package:finalltmcb/Widget/FilePickerUtil.dart';
import 'package:finalltmcb/Widget/ImagePickerButtonWidget.dart';
import 'package:finalltmcb/Widget/ImagesPreviewWidget.dart';
import 'package:finalltmcb/Widget/MediaHandlerWidget.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'dart:developer' as logger; // Import logger

// Define callback types
typedef OnTextMessageSent = Future<void> Function(String text);
typedef OnMediaMessageSent = Future<void> Function(
    List<ImageMessage> images, String? text);
typedef OnAudioMessageCreated = void Function(
    ChatMessage audioMessage); // For UI update
typedef OnFileMessageCreated = void Function(
    ChatMessage fileMessage); // For UI update
typedef OnVideoMessageCreated = void Function(
    ChatMessage videoMessage); // For UI update
typedef OnProcessingStateChanged = void Function(bool isProcessing);
typedef ShowNotification = void Function(String message,
    {bool isError, bool isSuccess, bool isInfo, Duration? duration});

class ChatInputWidget extends StatefulWidget {
  final String userId; // Needed for MediaHandler
  final OnTextMessageSent onTextMessageSent;
  final OnMediaMessageSent onMediaMessageSent;
  final OnAudioMessageCreated onAudioMessageCreated; // Renamed for clarity
  final OnFileMessageCreated onFileMessageCreated; // Renamed for clarity
  final OnVideoMessageCreated onVideoMessageCreated; // Renamed for clarity
  final OnProcessingStateChanged onProcessingStateChanged;
  final ShowNotification showNotification;

  const ChatInputWidget({
    Key? key,
    required this.userId,
    required this.onTextMessageSent,
    required this.onMediaMessageSent,
    required this.onAudioMessageCreated,
    required this.onFileMessageCreated,
    required this.onVideoMessageCreated,
    required this.onProcessingStateChanged,
    required this.showNotification,
  }) : super(key: key);

  @override
  _ChatInputWidgetState createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final TextEditingController _textController = TextEditingController();
  List<XFile> _selectedImages = [];
  bool _isAudioHandlerActive = false;
  bool _isProcessingFile = false;
  late MediaHandlerWidget _mediaHandler;

  @override
  void initState() {
    super.initState();
    _mediaHandler = MediaHandlerWidget(
      context: context,
      onMessageCreated: _handleMediaCreatedInternal,
      userId: widget.userId,
      onProcessingStart: () => _setProcessingState(true),
      onProcessingEnd: () => _setProcessingState(false),
      onError: (message, {bool isError = false, bool isSuccess = false, bool isInfo = false, Duration? duration}) {
        widget.showNotification(message, isError: true);
      },
    );
  }

  void _setProcessingState(bool isProcessing) {
    if (mounted) {
      setState(() {
        _isProcessingFile = isProcessing;
      });
      widget.onProcessingStateChanged(isProcessing);
    }
  }

  // Internal handler that decides which parent callback to call
  void _handleMediaCreatedInternal(ChatMessage message) {
    if (message.file != null) {
      widget.onFileMessageCreated(message);
    } else if (message.video != null) {
      widget.onVideoMessageCreated(message);
    } else if (message.audio != null) {
      widget.onAudioMessageCreated(message);
    }
    // Note: Image messages are handled separately via _handleSendAction
  }

  Future<ImageMessage?> _convertImageToBase64(XFile image) async {
    // This logic remains the same as in ChatContent
    try {
      final bytes = await image.readAsBytes();
      final base64Data = base64Encode(bytes);
      final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';

      print('Processing image:');
      print('Path: ${image.path}');
      print('Size: ${bytes.length} bytes');
      print('MIME type: $mimeType');
      print('Base64 length: ${base64Data.length}');
      print(
          'Base64 preview: ${base64Data.substring(0, math.min(50, base64Data.length))}...');

      return ImageMessage(
        base64Data: base64Data,
        mimeType: mimeType,
        size: bytes.length,
      );
    } catch (e) {
      print("Error converting image to base64: $e");
      widget.showNotification('Lỗi xử lý ảnh: $e', isError: true);
      return null;
    }
  }

  Future<void> _handleSendAction() async {
    final text = _textController.text;
    if (text.isEmpty && _selectedImages.isEmpty) return;

    // Disable input temporarily
    _setProcessingState(true);

    try {
      List<ImageMessage> processedImages = [];
      // Process images first
      if (_selectedImages.isNotEmpty) {
        print('Processing ${_selectedImages.length} images for send...');
        for (var image in List<XFile>.from(_selectedImages)) {
          // Create copy
          ImageMessage? imgMsg = await _convertImageToBase64(image);
          if (imgMsg != null) {
            processedImages.add(imgMsg);
          } else {
            // Handle error if needed, maybe notify user
            widget.showNotification('Không thể xử lý một hoặc nhiều ảnh.',
                isError: true);
          }
        }
        print('Processed ${processedImages.length} images.');
      }

      if (processedImages.isNotEmpty) {
        // Call the media message callback (images + optional text)
        await widget.onMediaMessageSent(
            processedImages, text.isNotEmpty ? text : null);
      } else if (text.isNotEmpty) {
        // Call the text message callback
        await widget.onTextMessageSent(text);
      }

      // Clear input fields after successful processing initiation
      _textController.clear();
      setState(() {
        _selectedImages.clear();
      });
    } catch (e, stackTrace) {
      logger.log("Error in _handleSendAction: $e",
          name: "ChatInputWidget", error: e, stackTrace: stackTrace);
      widget.showNotification('Lỗi khi chuẩn bị gửi tin nhắn.', isError: true);
    } finally {
      // Re-enable input
      _setProcessingState(false);
    }
  }

  void _updateSelectedImages(List<XFile> newImages) {
    if (mounted) {
      setState(() {
        // Add checks for duplicates or limits if needed
        _selectedImages.addAll(newImages);
      });
    }
  }

  void _removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      if (mounted) {
        setState(() {
          _selectedImages.removeAt(index);
        });
      }
    }
  }

  // --- File and Video Handling ---
  // These now primarily delegate to MediaHandlerWidget

  Future<void> _handleFileSend() async {
    logger.log("File send button tapped, delegating to MediaHandler...",
        name: "ChatInputWidget");
    if (_isProcessingFile) {
      logger.log("⚠️ Already processing, ignoring file request",
          name: "ChatInputWidget");
      widget.showNotification("Đang xử lý tệp khác...", isInfo: true);
      return;
    }
    // Let MediaHandlerWidget pick the file and call _handleMediaCreatedInternal via its callback
    await _mediaHandler.handleFileSend();
  }

  void _handleVideoSend() async {
    logger.log("Video send button tapped, delegating to MediaHandler...",
        name: "ChatInputWidget");
    if (_isProcessingFile) {
      logger.log("⚠️ Already processing, ignoring video request",
          name: "ChatInputWidget");
      widget.showNotification("Đang xử lý tệp khác...", isInfo: true);
      return;
    }
    // Let MediaHandlerWidget pick the video and call _handleMediaCreatedInternal via its callback
    await _mediaHandler.handleVideoSend();
  }

  // --- Audio Handling ---
  void _handleAudioRecordingStart() {
    if (mounted) {
      setState(() => _isAudioHandlerActive = true);
      // Optionally notify parent if ChatContent needs to know about recording state
      // widget.onAudioRecordingStateChanged(true);
    }
  }

  void _handleAudioRecordingEnd() {
    if (mounted) {
      setState(() => _isAudioHandlerActive = false);
      // Optionally notify parent
      // widget.onAudioRecordingStateChanged(false);
    }
  }

  // This method is called by the AudioHandlerWidget *within* this widget
  void _handleLocalAudioMessageSent(ChatMessage audioMessage) {
    // This simply forwards the message up to ChatContent via the callback
    widget.onAudioMessageCreated(audioMessage);
    _handleAudioRecordingEnd(); // Ensure UI resets
  }

  @override
  Widget build(BuildContext context) {
    if (_isAudioHandlerActive) {
      // Show only the Audio Handler when recording
      return Container(
        padding: const EdgeInsets.all(8.0),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey)),
        ),
        child: AudioHandlerWidget(
          showRecorder: true, // Explicitly show recorder UI
          onAudioMessageSent:
              _handleLocalAudioMessageSent, // Use the local handler
          onRecordingStart: _handleAudioRecordingStart, // Manage local state
          onRecordingEnd: _handleAudioRecordingEnd, // Manage local state
        ),
      );
    }

    // Show the standard input bar
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Preview selected images
          ImagesPreviewWidget(
            images: _selectedImages,
            onRemove: _removeImage,
          ),
          // Input Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Attachment Menu (File/Video) - delegates to _mediaHandler
              AttachmentMenuWidget(
                onFileSelected: () async {
                  _handleFileSend(); // Call async function without await
                },
                onVideoSelected: () async {
                  _handleVideoSend(); // Call async function without await
                },
                iconColor: Colors.red,
              ),
              // Text Input Field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(25)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: TextField(
                      controller: _textController,
                      enabled: !_isProcessingFile, // Disable TextField itself
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Aa',
                      ),
                      textInputAction:
                          TextInputAction.send, // Indicate send action
                      onSubmitted: (_) =>
                          _handleSendAction(), // Allow sending via keyboard action
                      minLines: 1,
                      maxLines: 5, // Allow multi-line input
                    ),
                  ),
                ),
              ),
              // Image Picker Button
              ImagePickerButtonWidget(
                onImagesSelected: _updateSelectedImages,
                iconColor: Colors.red,
              ),
              // Audio Recording Button - starts recording mode
              AudioHandlerWidget(
                showRecorder: false, // Only show the initial button
                onAudioMessageSent:
                    _handleLocalAudioMessageSent, // Callback for completion
                onRecordingStart:
                    _handleAudioRecordingStart, // Callback to switch UI state
                onRecordingEnd:
                    _handleAudioRecordingEnd, // Callback to switch UI state
              ),
              // Send Button (for text/images)
              IconButton(
                  onPressed: _isProcessingFile
                      ? null // Correct way to disable IconButton
                      : _handleSendAction,
                  icon: Icon(
                    Icons.send,
                    color: _isProcessingFile ? Colors.grey : Colors.red,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
