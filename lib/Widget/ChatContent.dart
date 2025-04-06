// Import UserList to access the static cache
import 'package:finalltmcb/ClientUdp/client_state.dart';
import 'package:finalltmcb/Controllers/GroupController.dart';
import 'package:finalltmcb/Model/AudioMessage.dart';
import 'package:finalltmcb/Model/MessageData.dart';
import 'package:finalltmcb/Service/MessageNotifier.dart';
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
  GroupController groupController; // Access the global instance
  ChatContent({
    Key? key,
    required this.userId,
    required this.groupController,
  }) : super(key: key);

  @override
  State<ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<ChatContent> {
  final Map<String, List<ChatMessage>> _userMessages = {};
  late String _currentUserName;
  late String _currentUserAvatar;
  bool _isGroupChat = false;
  late List<ChatMessage> listhistorymessage;
  List<String> _groupMembers = [];
  final ScrollController _scrollController = ScrollController();
  bool _isProcessingFile = false;
  bool _isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    _loadUserMessages();
    _initializeHistoryMessages();
    MessageNotifier.messageNotifier.addListener(_handleNewMessage);
  }

  void _initializeHistoryMessages() async {
    setState(() => _isLoading = true);

    try {
      if (widget.groupController.clientState != null) {
        final history = widget.groupController.clientState
                ?.allMessagesConverted[widget.userId] ??
            [];
        setState(() {
          listhistorymessage = history;
          // Clear existing messages before initializing
          _userMessages.clear();
          _userMessages[widget.userId] = List.from(history);
          _isLoading = false;
        });

        // Scroll to bottom without animation for initial load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          }
        });

        logger.log(
            'Successfully loaded ${history.length} history messages for userId: ${widget.userId}');
      }
    } catch (e) {
      logger.log('Error loading history messages: $e');
      setState(() {
        listhistorymessage = [];
        _userMessages[widget.userId] = [];
        _isLoading = false;
      });
    }
  }

  void _handleNewMessage() {
    final messageData = MessageNotifier.messageNotifier.value;
    if (messageData != null && mounted) {
      final roomId = messageData['roomId'];

      // Store message in global state regardless of current room
      if (widget.groupController.clientState != null) {
        final newMessage = ChatMessage(
          text: messageData['content'],
          isMe: false,
          name: messageData['name'],
          timestamp: DateTime.parse(messageData['timestamp']),
        );

        // Add to global state
        if (!widget.groupController.clientState!.allMessagesConverted
            .containsKey(roomId)) {
          widget.groupController.clientState!.allMessagesConverted[roomId] = [];
        }
        widget.groupController.clientState!.allMessagesConverted[roomId]!
            .add(newMessage);

        // Only update UI if message is for current room
        if (roomId == widget.userId) {
          setState(() {
            if (!_userMessages.containsKey(widget.userId)) {
              _userMessages[widget.userId] = [];
            }
            _userMessages[widget.userId]!.add(newMessage);
            listhistorymessage = _userMessages[widget.userId]!;
          });
          _scrollToBottom();
        }
      }
    }
  }

  @override
  void didUpdateWidget(ChatContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadUserMessages();
      _initializeHistoryMessages();
    }
  }

  void _loadUserMessages() {
    if (!_userMessages.containsKey(widget.userId)) {
      _userMessages[widget.userId] = [];
    }
    _fetchUserProfile();
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
        _currentUserAvatar = chatData!['avatar'] ?? 'assets/logoS.jpg';
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

  Future<void> _handleTextInputSubmitted(String text) async {
    if (text.isEmpty) return;
    final timestamp = DateTime.now();
    final uiMessage = ChatMessage(text: text, isMe: true, timestamp: timestamp);
    _addMessageToUI(uiMessage);

    try {
      await MessageController()
          .SendTextMessage(widget.userId, _groupMembers, text);
      logger
          .log('ChatContent: Called SendTextMessage for room ${widget.userId}');
    } catch (e, s) {
      logger.log("Error initiating text message send: $e",
          name: "ChatContent", error: e, stackTrace: s);
      _showTopNotification('Lỗi gửi tin nhắn văn bản', isError: true);
    }
  }

  Future<void> _handleMediaInputSubmitted(
      List<ImageMessage> images, String? text) async {
    if (images.isEmpty && (text == null || text.isEmpty)) return;
    final timestamp = DateTime.now();
    List<ChatMessage> uiMessagesToAdd = [];

    if (text != null && text.isNotEmpty) {
      uiMessagesToAdd
          .add(ChatMessage(text: text, isMe: true, timestamp: timestamp));
    }
    for (var img in images) {
      uiMessagesToAdd.add(ChatMessage(
        text: '',
        isMe: true,
        timestamp: timestamp,
        image: img.base64Data,
        mimeType: img.mimeType,
      ));
    }

    _addMultipleMessagesToUI(uiMessagesToAdd);

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
      } catch (e, s) {
        logger.log("Error sending media message: $e",
            name: "ChatContent", error: e, stackTrace: s);
        _showTopNotification('Lỗi gửi ảnh/media', isError: true);
      }
    });
  }

  void _handleAudioCreated(ChatMessage audioMessage) {
    _addMessageToUI(audioMessage);

    Future(() async {
      try {
        AudioData? audioData;
        if (audioMessage.isAudioPath && audioMessage.audio != null) {
          final File audioFile = File(audioMessage.audio!);
          final bytes = await audioFile.readAsBytes();
          audioData = AudioData(
            base64Data: base64Encode(bytes),
            duration: 0,
            mimeType: lookupMimeType(audioMessage.audio!) ?? 'audio/mp4',
            size: bytes.length,
          );
        } else if (audioMessage.audio != null) {
          final bytes = base64Decode(audioMessage.audio!);
          audioData = AudioData(
            base64Data: audioMessage.audio!,
            duration: 0,
            mimeType: 'audio/mp4',
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
      } catch (e, s) {
        logger.log("Error sending audio message: $e",
            name: "ChatContent", error: e, stackTrace: s);
        _showTopNotification('Lỗi gửi âm thanh', isError: true);
      }
    });
  }

  void _handleFileCreated(ChatMessage fileMessage) {
    _addMessageToUI(fileMessage);

    Future(() async {
      try {
        if (fileMessage.file == null) {
          logger.log('Warning: FileMessage in callback is null.',
              name: "ChatContent");
          return;
        }

        final messageDataToSend = MessageData(
            text: null,
            images: [],
            audios: [],
            files: [fileMessage.file!],
            video: null,
            timestamp: fileMessage.timestamp);
        _logMessageDataForServer(messageDataToSend);
      } catch (e, s) {
        logger.log("Error sending file message: $e",
            name: "ChatContent", error: e, stackTrace: s);
        _showTopNotification('Lỗi gửi tệp', isError: true);
      }
    });
  }

  void _handleVideoCreated(ChatMessage videoMessage) {
    _addMessageToUI(videoMessage);

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
      } catch (e, s) {
        logger.log("Error sending video message: $e",
            name: "ChatContent", error: e, stackTrace: s);
        _showTopNotification('Lỗi gửi video', isError: true);
      }
    });
  }

  void _addMessageToUI(ChatMessage message) {
    if (!mounted) return;

    setState(() {
      if (!_userMessages.containsKey(widget.userId)) {
        _userMessages[widget.userId] = [];
      }

      // Check for duplicates before adding
      bool isDuplicate = _userMessages[widget.userId]!.any((m) =>
          m.text == message.text &&
          m.timestamp.difference(message.timestamp).inSeconds.abs() < 1);

      if (!isDuplicate) {
        _userMessages[widget.userId]!.add(message);
        listhistorymessage = _userMessages[widget.userId]!;

        // Update global state
        if (widget.groupController.clientState != null) {
          if (!widget.groupController.clientState!.allMessagesConverted
              .containsKey(widget.userId)) {
            widget.groupController.clientState!
                .allMessagesConverted[widget.userId] = [];
          }
          widget
              .groupController.clientState!.allMessagesConverted[widget.userId]!
              .add(message);
        }
      }
    });
    _scrollToBottom();
  }

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
      final loggableJson = json.decode(json.encode(jsonData));

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
    final overlay = Overlay.of(context);
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

    Future.delayed(duration ?? Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  void _handleFileDownload(FileMessage file) async {
    print("Attempting to download/open file: ${file.fileName}");
    await FileDownloader.downloadFile(file, context);
  }

  @override
  void dispose() {
    MessageNotifier.messageNotifier.removeListener(_handleNewMessage);
    _scrollController.dispose();
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
              key: ValueKey(widget.userId),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUserName,
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
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : messages.isEmpty
                    ? Center(
                        child: Text('No messages yet. Start a conversation!'))
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
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
