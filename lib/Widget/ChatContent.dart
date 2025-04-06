// Import UserList to access the static cache
import 'package:finalltmcb/ClientUdp/client_state.dart';
import 'package:finalltmcb/Model/AudioMessage.dart';
import 'package:finalltmcb/Model/MessageData.dart';
import 'package:finalltmcb/Widget/AudioHandlerWidget.dart'; // Import the new widget
import 'package:finalltmcb/Widget/UserList.dart';
import 'package:finalltmcb/Model/ChatMessage.dart';
import 'package:finalltmcb/Model/ImageMessage.dart';
import 'dart:io';
import 'package:finalltmcb/Widget/ChatBubble.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:math' as math; // Add this import for min function
import 'package:finalltmcb/Widget/FilePickerUtil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:finalltmcb/Widget/ImagePickerButtonWidget.dart';
import 'package:finalltmcb/Widget/ImageViewerWidget.dart';
import 'package:finalltmcb/Widget/FullScreenImageViewer.dart';
import 'package:finalltmcb/Widget/ImagesPreviewWidget.dart';
import 'package:finalltmcb/Widget/AttachmentMenuWidget.dart';
import 'package:finalltmcb/Widget/MediaHandlerWidget.dart';
import 'dart:typed_data'; // Import typed_data
import 'package:mime/mime.dart';
import 'package:finalltmcb/Model/VideoFileMessage.dart'; // Add import for VideoFileMessage
import 'package:finalltmcb/Controllers/MessageController.dart'; // Import MessageController
import 'dart:developer' as logger; // Import logger
import 'package:finalltmcb/Widget/ChatInputWidget.dart'; // Import the new widget

class ChatContent extends StatefulWidget {
  final String userId;

  const ChatContent({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<ChatContent> {
  // Mock data for demonstration
  // In a real app, you would fetch messages for the specific user from a database or API
  final Map<String, List<ChatMessage>> _userMessages = {};
  late String _currentUserName;
  late String _currentUserAvatar;
  bool _isGroupChat = false;
  List<String> _groupMembers = [];

  // ScrollController for ListView
  final ScrollController _scrollController = ScrollController();

  // Add a flag to track if a file is being processed
  bool _isProcessingFile = false;

  @override
  void initState() {
    super.initState();
    _loadUserMessages();
  }

  @override
  void didUpdateWidget(ChatContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadUserMessages();
    }
  }

  // Load messages for the current user
  void _loadUserMessages() {
    // In a real app, you would fetch these from a database
    // For now, we'll create some mock data if it doesn't exist
    if (!_userMessages.containsKey(widget.userId)) {
      _userMessages[widget.userId] = [];
    }

    // Get user profile information
    _fetchUserProfile();

    // Scroll to the bottom after loading messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _fetchUserProfile() {
    Map<String, dynamic>? chatData;
    if (MessageList.cachedMessages != null) {
      for (var chat in MessageList.cachedMessages!) {
        if (chat['id'] == widget.userId) {
          chatData = chat;
          break;
        }
      }
    }

    if (chatData != null) {
      setState(() {
        _currentUserName = chatData!['name'] ?? 'Unknown Chat';
        _currentUserAvatar =
            chatData!['avatar'] ?? 'assets/logoS.jpg'; // Default avatar
        _isGroupChat = chatData!['isGroup'] ?? false;
        if (_isGroupChat) {
          _groupMembers = List<String>.from(chatData!['members'] ?? []);
        } else {
          _groupMembers = [];
        }
      });
    } else {
      setState(() {
        _currentUserName = "Unknown Chat";
        _currentUserAvatar = "assets/logoS.jpg";
        _isGroupChat = false;
        _groupMembers = [];
      });
    }
  }

  // --- New Handler Methods for Callbacks from ChatInputWidget ---

  Future<void> _handleTextInputSubmitted(String text) async {
    if (text.isEmpty) return;
    final timestamp = DateTime.now();

    // 1. Update UI
    final uiMessage = ChatMessage(text: text, isMe: true, timestamp: timestamp);
    _addMessageToUI(uiMessage);

    // 2. Send in Background
    Future(() async {
      try {
        final messageDataToSend = MessageData(
            text: text,
            images: [],
            audios: [],
            files: [],
            video: null,
            timestamp: timestamp);
        _logMessageDataForServer(messageDataToSend);
        await MessageController().SendMessage(messageDataToSend);
      } catch (e, s) {
        logger.log("Error sending text message: $e",
            name: "ChatContent", error: e, stackTrace: s);
        _showTopNotification('Lỗi gửi tin nhắn văn bản', isError: true);
        // Optionally update message status in UI to failed
      }
    });
  }

  Future<void> _handleMediaInputSubmitted(
      List<ImageMessage> images, String? text) async {
    if (images.isEmpty && (text == null || text.isEmpty)) return;
    final timestamp = DateTime.now();
    List<ChatMessage> uiMessagesToAdd = [];

    // 1. Prepare UI Messages
    if (text != null && text.isNotEmpty) {
      uiMessagesToAdd
          .add(ChatMessage(text: text, isMe: true, timestamp: timestamp));
    }
    for (var img in images) {
      uiMessagesToAdd.add(ChatMessage(
        text: '', // No text for image bubbles
        isMe: true,
        timestamp: timestamp,
        image: img.base64Data, // For UI bubble
        mimeType: img.mimeType,
      ));
    }

    // 2. Update UI
    _addMultipleMessagesToUI(uiMessagesToAdd);

    // 3. Send in Background
    Future(() async {
      try {
        final messageDataToSend = MessageData(
            text: text,
            images: images,
            audios: [],
            files: [],
            video: null,
            timestamp: timestamp);
        _logMessageDataForServer(messageDataToSend);
        // await MessageController().SendMessage(messageDataToSend);
      } catch (e, s) {
        logger.log("Error sending media message: $e",
            name: "ChatContent", error: e, stackTrace: s);
        _showTopNotification('Lỗi gửi ảnh/media', isError: true);
      }
    });
  }

  // Handles audio message created by ChatInputWidget (via AudioHandler)
  void _handleAudioCreated(ChatMessage audioMessage) {
    // 1. Update UI
    _addMessageToUI(audioMessage);

    // 2. Process and Send in Background
    Future(() async {
      try {
        AudioData? audioData; // Re-process if needed
        if (audioMessage.isAudioPath && audioMessage.audio != null) {
          final File audioFile = File(audioMessage.audio!);
          final bytes = await audioFile.readAsBytes();
          audioData = AudioData(
            base64Data: base64Encode(bytes),
            duration: 0, // TODO: Get duration
            mimeType: lookupMimeType(audioMessage.audio!) ?? 'audio/mp4',
            size: bytes.length,
          );
        } else if (audioMessage.audio != null) {
          // Assume base64
          final bytes = base64Decode(audioMessage.audio!);
          audioData = AudioData(
            base64Data: audioMessage.audio!,
            duration: 0,
            mimeType: 'audio/mp4', // Default
            size: bytes.length,
          );
        } else {
          logger.log(
              'Warning: No valid audio data found in ChatMessage for sending.',
              name: "ChatContent");
          return;
        }

        final messageDataToSend = MessageData(
            text: null,
            images: [],
            audios: [audioData],
            files: [],
            video: null,
            timestamp: audioMessage.timestamp);
        _logMessageDataForServer(messageDataToSend);
        // await MessageController().SendMessage(messageDataToSend);
      } catch (e, s) {
        logger.log("Error sending audio message: $e",
            name: "ChatContent", error: e, stackTrace: s);
        _showTopNotification('Lỗi gửi âm thanh', isError: true);
      }
    });
  }

  // Handles file message created by ChatInputWidget (via MediaHandler)
  void _handleFileCreated(ChatMessage fileMessage) {
    // 1. Update UI
    _addMessageToUI(fileMessage);

    // 2. Send in Background
    Future(() async {
      try {
        if (fileMessage.file == null) {
          logger.log('Warning: FileMessage in callback is null.',
              name: "ChatContent");
          return;
        }
        // Ensure bytes are included for sending if needed by the model/controller
        // If FileMessage.toJson handles this, it might be okay.
        // If not, ensure _handleFileSend in ChatInput includes bytes.

        final messageDataToSend = MessageData(
            text: null,
            images: [],
            audios: [],
            files: [fileMessage.file!],
            video: null,
            timestamp: fileMessage.timestamp);
        _logMessageDataForServer(messageDataToSend);
        // await MessageController().SendMessage(messageDataToSend);
      } catch (e, s) {
        logger.log("Error sending file message: $e",
            name: "ChatContent", error: e, stackTrace: s);
        _showTopNotification('Lỗi gửi tệp', isError: true);
      }
    });
  }

  // Handles video message created by ChatInputWidget (via MediaHandler)
  void _handleVideoCreated(ChatMessage videoMessage) {
    // 1. Update UI
    _addMessageToUI(videoMessage);

    // 2. Send in Background
    Future(() async {
      try {
        if (videoMessage.video == null) {
          logger.log('Warning: VideoFileMessage in callback is null.',
              name: "ChatContent");
          return;
        }
        final messageDataToSend = MessageData(
            text: null,
            images: [],
            audios: [],
            files: [],
            video: videoMessage.video,
            timestamp: videoMessage.timestamp);
        _logMessageDataForServer(messageDataToSend);
        // await MessageController().SendMessage(messageDataToSend);
      } catch (e, s) {
        logger.log("Error sending video message: $e",
            name: "ChatContent", error: e, stackTrace: s);
        _showTopNotification('Lỗi gửi video', isError: true);
      }
    });
  }

  // Helper to add a single message to UI
  void _addMessageToUI(ChatMessage message) {
    if (!mounted) return;
    setState(() {
      if (!_userMessages.containsKey(widget.userId)) {
        _userMessages[widget.userId] = [];
      }
      _userMessages[widget.userId]!.add(message);
    });
    _scrollToBottom();
  }

  // Helper to add multiple messages to UI
  void _addMultipleMessagesToUI(List<ChatMessage> messages) {
    if (!mounted) return;
    setState(() {
      if (!_userMessages.containsKey(widget.userId)) {
        _userMessages[widget.userId] = [];
      }
      _userMessages[widget.userId]!.addAll(messages);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted && _scrollController.hasClients) {
            try {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            } catch (e) {
              print("Error scrolling to bottom: $e");
            }
          }
        });
      }
    });
  }

  void _viewImage(String base64Image) {
    ImageViewerWidget.viewImage(context, base64Image);
  }

  void _logMessageDataForServer(MessageData messageData) {
    try {
      final jsonData = messageData.toJson();
      final loggableJson = json.decode(json.encode(jsonData)); // Deep copy

      if (loggableJson['images'] != null) {
        for (var img in loggableJson['images']) {
          if (img['base64Data'] is String) {
            img['base64Data'] =
                '${(img['base64Data'] as String).substring(0, math.min(50, (img['base64Data'] as String).length))}... (truncated)';
          }
        }
      }
      if (loggableJson['audios'] != null) {
        for (var aud in loggableJson['audios']) {
          if (aud['base64Data'] is String) {
            aud['base64Data'] =
                '${(aud['base64Data'] as String).substring(0, math.min(50, (aud['base64Data'] as String).length))}... (truncated)';
          }
        }
      }
      if (loggableJson['files'] != null) {
        for (var file in loggableJson['files']) {
          if (file['fileData'] is String) {
            file['fileData'] =
                '${(file['fileData'] as String).substring(0, math.min(50, (file['fileData'] as String).length))}... (truncated)';
          }
          if (file['fileBytes'] != null) {
            file.remove('fileBytes');
          }
        }
      }
      if (loggableJson['video'] != null &&
          loggableJson['video']['base64Data'] is String) {
        loggableJson['video']['base64Data'] =
            '${(loggableJson['video']['base64Data'] as String).substring(0, math.min(50, (loggableJson['video']['base64Data'] as String).length))}... (truncated)';
      }

      print("\n----- Message Data to be sent to server -----");
      print(JsonEncoder.withIndent('  ').convert(loggableJson));
      print("----- End Message Data -----");
    } catch (e) {
      print("Error logging/encoding MessageData: $e");
    }
  }

  void _showTopNotification(String message,
      {bool isError = false,
      bool isSuccess = false,
      bool isInfo = false,
      Duration? duration}) {
    // Sử dụng overlay để hiển thị thông báo ở phía trên
    final overlay = Overlay.of(context);

    // Determine background color based on message type
    final Color backgroundColor = isError
        ? Colors.red.shade700
        : isSuccess
            ? Colors.green.shade700
            : isInfo
                ? Colors.blue.shade700
                : Colors.grey.shade700;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          color: backgroundColor,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Tự động đóng sau một khoảng thời gian
    Future.delayed(duration ?? Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  void _handleFileDownload(FileMessage file) async {
    print("Attempting to download/open file: ${file.fileName}");

    // Use the platform-safe downloader
    await FileDownloader.downloadFile(file, context);
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the scroll controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _userMessages[widget.userId] ?? [];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(_currentUserAvatar),
              radius: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              key: ValueKey(widget.userId), // Force rebuild on ID change
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUserName, // This should now be correct
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_isGroupChat)
                    Text(
                      "${_groupMembers.length} members",
                      style: TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
            IconButton(
                onPressed: () {/* TODO: Implement info/more options menu */},
                icon: Icon(Icons.more_vert)),
          ],
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(child: Text('No messages yet. Start a conversation!'))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    padding: EdgeInsets.only(bottom: 16),
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      if (message.isMe) {
                        return ChatBubble(
                          message: message,
                          onFileDownload: _handleFileDownload,
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 4.0),
                                child: CircleAvatar(
                                  backgroundImage:
                                      AssetImage(_currentUserAvatar),
                                  radius: 16,
                                ),
                              ),
                              Expanded(
                                child: ChatBubble(
                                  message: message,
                                  onFileDownload: _handleFileDownload,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
          ),
          ChatInputWidget(
            userId: widget.userId,
            onTextMessageSent: _handleTextInputSubmitted,
            onMediaMessageSent: _handleMediaInputSubmitted,
            onAudioMessageCreated: _handleAudioCreated,
            onFileMessageCreated: _handleFileCreated,
            onVideoMessageCreated: _handleVideoCreated,
            onProcessingStateChanged: (isProcessing) {
              if (mounted) {
                // Check if widget is still in the tree
                setState(() => _isProcessingFile = isProcessing);
              }
            },
            showNotification: _showTopNotification,
          ),
        ],
      ),
    );
  }
}
