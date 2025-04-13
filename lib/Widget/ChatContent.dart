// Import UserList to access the static cache
import 'package:finalltmcb/ClientUdp/client_state.dart';
import 'package:finalltmcb/ClientUdp/udp_client_singleton.dart';
import 'package:finalltmcb/Controllers/GroupController.dart';
import 'package:finalltmcb/File/Models/MediaPlaceholder.dart';
import 'package:finalltmcb/File/Models/MessageContentParser.dart';
import 'package:finalltmcb/File/Models/file_constants.dart';
import 'package:finalltmcb/Model/AudioMessage.dart';
import 'package:finalltmcb/Model/FileTransferQueue.dart';
import 'package:finalltmcb/Model/MessageData.dart';
import 'package:finalltmcb/Service/FileDownloadNotifier.dart';
import 'package:finalltmcb/Service/MessageNotifier.dart';
import 'package:finalltmcb/Widget/AudioHandlerWidget.dart'; // Import the new widget
import 'package:finalltmcb/Widget/UserList.dart';
import 'package:finalltmcb/Model/ChatMessage.dart';
import 'package:finalltmcb/Model/ImageMessage.dart';
import 'dart:io';
import 'package:finalltmcb/Widget/ChatBubble.dart';
import 'package:finalltmcb/constants/colors.dart';
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
  GroupController groupController;
  MessageController messageController; // Access the global instance
  ChatContent({
    Key? key,
    required this.userId,
    required this.groupController,
    required this.messageController, // Pass the global instance
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
  bool _isProcessingGeminiRequest = false; // Thêm trạng thái đang chờ xử lý cho gu_50f61f8f

  @override
  void initState() {
    super.initState();
    _loadUserMessages();
    _initializeHistoryMessages();
    MessageNotifier.messageNotifier.addListener(_handleNewMessage);
    // Add file download listener
    FileDownloadNotifier.instance.addListener(_handleFileDownloadNotification);

    // Add room notification listener to reinitialize when new rooms are created
    MessageNotifier.messageNotifierRoom.addListener(_handleNewRoom);

    // Thêm listener cho việc cập nhật chat bubble
    MessageNotifier.message.addListener(_handleChatBubbleUpdate);
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
          _userMessages.clear();
          _userMessages[widget.userId] = List.from(history);
          _isLoading = false;
        });

        // Use jumpTo for immediate scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            Future.delayed(Duration(milliseconds: 100), () {
              if (mounted && _scrollController.hasClients) {
                _scrollController
                    .jumpTo(_scrollController.position.maxScrollExtent);
              }
            });
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
    final udpClient = UdpClientSingleton();
    if (messageData != null &&
        mounted &&
        messageData['sender'] != udpClient.clientState?.currentChatId) {
      final roomId = messageData['roomId'];

      // Store message in global state regardless of current room
      if (widget.groupController.clientState != null) {
        final newMessage = ChatMessage(
          text: messageData['content'],
          isMe: false,
          // Use sender_chatid from server or fallback to name
          name: messageData['sender_chatid'] ??
              messageData['sender'] ??
              messageData['name'] ??
              'Unknown',
          timestamp: DateTime.parse(messageData['timestamp']),
        );

        // Initialize the messages list for this room if it doesn't exist
        // widget.groupController.clientState!.allMessagesConverted
        //     .putIfAbsent(roomId, () => []);
        // widget.groupController.clientState!.allMessagesConverted[roomId]!
        //     .add(newMessage);

        // Debug prints
        print("Received message for room: $roomId");
        print("Currently viewing room: ${widget.userId}");

        // Only update UI if message is for current room
        if(roomId == "gu_50f61f8f"){
          setState(() {
            _isProcessingGeminiRequest = false;
          });
        }

        if (roomId == widget.userId) {
          setState(() {
            _userMessages.putIfAbsent(widget.userId, () => []);
            _userMessages[widget.userId]!.add(newMessage);
            listhistorymessage = _userMessages[widget.userId]!;
          });
          _scrollToBottom();
        }
      }
    }
  }

  void _handleFileDownloadNotification() {
    final downloadData = FileDownloadNotifier.instance.value;
    if (downloadData != null &&
        mounted &&
        downloadData['roomId'] == widget.userId) {
      final newMessage = downloadData['message'] as ChatMessage;
        if(widget.userId == "gu_50f61f8f"){
          setState(() {
            _isProcessingGeminiRequest = false;
          });
        }

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

  // Handle notifications about new rooms being created
  void _handleNewRoom() {
    final roomData = MessageNotifier.messageNotifierRoom.value;
    if (roomData == null || !mounted) return;

    final roomId = roomData['room_id'];

    // Check if this is the room we're currently viewing
    if (roomId == widget.userId) {
      // Reinitialize the room data since it's a new room
      _loadUserMessages();
      _initializeHistoryMessages();
      print("Reinitialized view for newly created room: $roomId");
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
    final userName = widget.groupController.clientState?.currentChatId ?? "Me";
    final uiMessage = ChatMessage(
        text: text, isMe: true, timestamp: timestamp, name: userName);
    _addMessageToUI(uiMessage);

    try {
      if(widget.userId=="gu_50f61f8f"){
        setState(() {
          _isProcessingGeminiRequest = true;
        });
      }
      await widget.messageController
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
    final userName = widget.groupController.clientState?.currentChatId ?? "Me";
    List<ChatMessage> uiMessagesToAdd = [];

    // Handle text message
    if (text != null && text.isNotEmpty) {
      final textMessage =
          ChatMessage(text: text, isMe: true, timestamp: timestamp);
      uiMessagesToAdd.add(textMessage);

      try {
        await widget.messageController
            .SendTextMessage(widget.userId, _groupMembers, text);
        logger.log(
            'ChatContent: Called SendTextMessage for room ${widget.userId}');
      } catch (e, s) {
        logger.log("Error initiating text message send: $e",
            name: "ChatContent", error: e, stackTrace: s);
        _showTopNotification('Lỗi gửi tin nhắn văn bản', isError: true);
      }
    }

    // Handle image messages
    if (images.isNotEmpty) {
      final currentChatId = UdpClientSingleton().clientState?.currentChatId;
      if (currentChatId == null) {
        logger.log('Warning: No current chat ID available.',
            name: "ChatContent");
        _showTopNotification('Lỗi: Chưa đăng nhập', isError: true);
        return;
      }

      for (var img in images) {
        // Add to UI
        uiMessagesToAdd.add(ChatMessage(
          text: '',
          isMe: true,
          timestamp: timestamp,
          image: img.base64Data,
          mimeType: img.mimeType,
        ));
        widget.groupController.clientState!.allMessagesConverted[widget.userId]!
            .add(ChatMessage(
          text: '',
          isMe: true,
          timestamp: timestamp,
          image: img.base64Data,
          mimeType: img.mimeType,
        )); // Add to UI

        // Create temporary file from base64
        try {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File(
              '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
          await tempFile.writeAsBytes(base64Decode(img.base64Data));

          final actualFileSize = await tempFile.length();
          final actualTotalPackages = (actualFileSize / (1024 * 32)).ceil();
          final item = FileTransferItem(
            status: FileConstants.Action_Status_File_Send,
            currentChatId: currentChatId,
            userId: widget.userId,
            filePath: tempFile.path,
            actualFileSize: actualFileSize,
            fileType: 'image',
            actualTotalPackages: (actualFileSize / (1024 * 32)).ceil(),
          );

          FileTransferQueue.instance.addToQueue(item);
          // Add to global queue
          // FileTransferQueue().addToQueue(FileTransferItem(
          //   currentChatId: currentChatId,
          //   userId: widget.userId,
          //   filePath: tempFile.path,
          //   actualFileSize: actualFileSize,
          //   fileType: 'image',
          //   actualTotalPackages: actualTotalPackages,
          // ));
        } catch (e, s) {
          logger.log("Error preparing image for sending: $e",
              name: "ChatContent", error: e, stackTrace: s);
          _showTopNotification('Lỗi xử lý ảnh', isError: true);
        }
      }
    }

    // Update UI with all messages
    _addMultipleMessagesToUI(uiMessagesToAdd);
  }

  void _handleAudioCreated(ChatMessage audioMessage) {
    final userName = widget.groupController.clientState?.currentChatId ?? "Me";
    final messageWithName = ChatMessage(
        text: audioMessage.text,
        isMe: audioMessage.isMe,
        timestamp: audioMessage.timestamp,
        audio: audioMessage.audio,
        isAudioPath: audioMessage.isAudioPath,
        name: userName);
    _addMessageToUI(messageWithName);

    Future(() async {
      try {
        AudioData? audioData;
        String filePath = '';
        int actualFileSize = 0;
        final currentChatId = UdpClientSingleton().clientState?.currentChatId;
        if (currentChatId == null) {
          logger.log('Warning: No current chat ID available.',
              name: "ChatContent");
          _showTopNotification('Lỗi: Chưa đăng nhập', isError: true);
          return;
        }

        if (audioMessage.isAudioPath && audioMessage.audio != null) {
          final File audioFile = File(audioMessage.audio!);
          final bytes = await audioFile.readAsBytes();
          filePath = audioMessage.audio!;
          actualFileSize = bytes.length;
          final actualTotalPackages = (actualFileSize / (1024 * 32)).ceil();
          final fileType = 'audio';
          audioData = AudioData(
            base64Data: base64Encode(bytes),
            duration: 0,
            mimeType: lookupMimeType(audioMessage.audio!) ?? 'audio/mp4',
            size: bytes.length,
          );
          try {
            // Send file message first
            final item = FileTransferItem(
              status: FileConstants.Action_Status_File_Send,
              currentChatId: currentChatId,
              userId: widget.userId,
              filePath: filePath,
              actualFileSize: actualFileSize,
              fileType: fileType,
              actualTotalPackages: actualTotalPackages,
            );

            FileTransferQueue.instance.addToQueue(item);
          } catch (e, s) {
            logger.log("Error sending audio file: $e",
                name: "ChatContent", error: e, stackTrace: s);
            _showTopNotification('Lỗi gửi audio', isError: true);
            return;
          }
        } else {
          logger.log(
              'Warning: No valid audio data found in ChatMessage for sending.',
              name: "ChatContent");
          return;
        }
      } catch (e, s) {
        logger.log("Error sending audio message: $e",
            name: "ChatContent", error: e, stackTrace: s);
        _showTopNotification('Lỗi gửi âm thanh', isError: true);
      }
    });
  }

  void _handleFileCreated(ChatMessage fileMessage) {
    try {
      if (fileMessage.file == null) {
        logger.log('Warning: FileMessage in callback is null.',
            name: "ChatContent");
        return;
      }

      final currentChatId = UdpClientSingleton().clientState?.currentChatId;
      if (currentChatId == null) {
        logger.log('Warning: No current chat ID available.',
            name: "ChatContent");
        _showTopNotification('Lỗi: Chưa đăng nhập', isError: true);
        return;
      }

      final fileInfo = fileMessage.file!;

      // Verify file exists and is readable
      final file = File(fileInfo.filePath);
      if (!file.existsSync()) {
        logger.log('Warning: File does not exist: ${fileInfo.filePath}',
            name: "ChatContent");
        _showTopNotification('Lỗi: File không tồn tại', isError: true);
        return;
      }

      // Get actual file size
      final actualFileSize = file.lengthSync();
      final actualTotalPackages = (actualFileSize / (1024 * 32)).ceil();

      logger.log('File details:', name: "ChatContent");
      logger.log('Path: ${fileInfo.filePath}', name: "ChatContent");
      logger.log('Size: $actualFileSize bytes', name: "ChatContent");
      logger.log('Packages: $actualTotalPackages', name: "ChatContent");

      // Add message to UI before sending
      _addMessageToUI(fileMessage);

      final item = FileTransferItem(
        status: FileConstants.Action_Status_File_Send,
        currentChatId: currentChatId,
        userId: widget.userId,
        filePath: fileInfo
            .filePath, // Fix: Use fileInfo.filePath instead of undefined filePath
        actualFileSize:
            actualFileSize, // Fix: Use actualFileSize instead of undefined fileSize
        fileType: 'file',
        actualTotalPackages:
            actualTotalPackages, // Fix: Use actualTotalPackages
      );

      logger.log('Adding file to transfer queue', name: "ChatContent");
      FileTransferQueue.instance.addToQueue(item);
    } catch (e, stackTrace) {
      logger.log('Error handling file creation: $e', name: "ChatContent");
      logger.log('Stack trace: $stackTrace', name: "ChatContent");
      _showTopNotification('Lỗi xử lý file', isError: true);
    }
  }

  void _handleVideoCreated(ChatMessage videoMessage) {
    try {
      if (videoMessage.video == null) {
        logger.log('Warning: VideoFileMessage in callback is null.',
            name: "ChatContent");
        return;
      }

      final currentChatId = UdpClientSingleton().clientState?.currentChatId;
      if (currentChatId == null) {
        logger.log('Warning: No current chat ID available.',
            name: "ChatContent");
        _showTopNotification('Lỗi: Chưa đăng nhập', isError: true);
        return;
      }

      final videoInfo = videoMessage.video!;

      // Verify video exists and is readable
      final file = File(videoInfo.localPath);
      if (!file.existsSync()) {
        logger.log('Warning: Video file does not exist: ${videoInfo.localPath}',
            name: "ChatContent");
        _showTopNotification('Lỗi: File video không tồn tại', isError: true);
        return;
      }

      // Get actual file size
      final actualFileSize = file.lengthSync();
      final actualTotalPackages = (actualFileSize / (1024 * 32)).ceil();

      logger.log('Video details:', name: "ChatContent");
      logger.log('Path: ${videoInfo.localPath}', name: "ChatContent");
      logger.log('Size: $actualFileSize bytes', name: "ChatContent");
      logger.log('Packages: $actualTotalPackages', name: "ChatContent");

      // Add message to UI before sending
      _addMessageToUI(videoMessage);

      final item = FileTransferItem(
        status: FileConstants.Action_Status_File_Send,
        currentChatId: currentChatId,
        userId: widget.userId,
        filePath: videoInfo.localPath,
        actualFileSize: actualFileSize,
        fileType: 'video',
        actualTotalPackages: actualTotalPackages,
      );

      logger.log('Adding video to transfer queue', name: "ChatContent");
      FileTransferQueue.instance.addToQueue(item);
    } catch (e, stackTrace) {
      logger.log('Error handling video creation: $e', name: "ChatContent");
      logger.log('Stack trace: $stackTrace', name: "ChatContent");
      _showTopNotification('Lỗi xử lý video', isError: true);
    }
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

  Future<void> _handleFileDownload(FileMessage file) async {
    print("Attempting to download/open file: ${file.fileName}");
    await FileDownloader.downloadFile(file, context);
  }

  void dispose() {
    MessageNotifier.messageNotifier.removeListener(_handleNewMessage);
    _scrollController.dispose();
    FileDownloadNotifier.instance
        .removeListener(_handleFileDownloadNotification);
    MessageNotifier.messageNotifierRoom.removeListener(_handleNewRoom);
    // Hủy đăng ký listener cho cập nhật ChatBubble
    MessageNotifier.message.removeListener(_handleChatBubbleUpdate);
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
        backgroundColor: AppColors.messengerBlue,
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
                        itemCount: messages.length + (_isProcessingGeminiRequest && widget.userId == 'gu_50f61f8f' ? 1 : 0),
                        padding: EdgeInsets.only(bottom: 16),
                        itemBuilder: (context, index) {
                          // Nếu đây là phần tử cuối cùng và đang chờ xử lý Gemini
                          if (_isProcessingGeminiRequest && 
                              widget.userId == 'gu_50f61f8f' && 
                              index == messages.length) {
                            // Hiển thị thông báo "đang chờ xử lý"
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                child: Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[700]!),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Đang chờ xử lý...",
                                        style: TextStyle(color: Colors.grey[800]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                          final message = messages[index];

                          // Kiểm tra nếu tin nhắn có định dạng file_path
                          if (message.text.startsWith('file_path ')) {
                            // Xử lý hiển thị widget placeholder cho file đang chờ
                            return _buildFilePathPlaceholder(message, index);
                          }

                          // Logic hiển thị tin nhắn thông thường
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

  // Widget hiển thị placeholder cho file đang chờ tải
  Widget _buildFilePathPlaceholder(ChatMessage message, int index) {
    // Phân tích thông tin từ định dạng: file_path [filename] chat_id [chat_id] room_id [room_id] file_type [type]
    final regex = RegExp(
        r'^file_path\s+(.*?)\s+chat_id\s+(.*?)\s+room_id\s+(.*?)(?:\s+file_type\s+(.*?))?$',
        caseSensitive: false // Không phân biệt hoa thường cho các keyword
        );

    final match = regex.firstMatch(message.text);

    if (match == null || match.groupCount < 3) {
      // Nếu không khớp mẫu hoặc thiếu các nhóm bắt buộc (filename, chat_id, room_id)
      print(
          "Lỗi phân tích định dạng tin nhắn file: ${message.text}"); // Thêm log để debug
      return Text('Định dạng file không hợp lệ');
    }

    // Trích xuất các nhóm, loại bỏ khoảng trắng thừa và xử lý null an toàn
    final fileName = match.group(1)?.trim() ?? '';
    final chatId = match.group(2)?.trim() ?? '';
    final roomId = match.group(3)?.trim() ?? '';
    // Xử lý file_type (nhóm 4) là tùy chọn
    // Nếu group(4) tồn tại và không rỗng thì lấy giá trị, ngược lại mặc định là 'file'
    final fileType = (match.group(4)?.trim() ?? '').isNotEmpty
        ? match.group(4)!.trim()
        : 'file';
    _addToDownloadQueue(chatId, roomId, fileName, fileType);
    // Chọn biểu tượng phù hợp với loại file
    IconData fileIcon;
    switch (fileType.toLowerCase()) {
      case 'image':
        fileIcon = Icons.image;
        break;
      case 'video':
        fileIcon = Icons.videocam;
        break;
      case 'audio':
        fileIcon = Icons.audiotrack;
        break;
      default:
        fileIcon = Icons.insert_drive_file;
    }

    // Widget placeholder với màu xám
    Widget placeholderWidget = Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(fileIcon, size: 20, color: Colors.grey[700]),
          SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fileName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  'Đang tải...',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                LinearProgressIndicator(
                  backgroundColor: Colors.grey[400],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                )
              ],
            ),
          ),
        ],
      ),
    );

    // Đặt placeholder vào vị trí phù hợp (trái/phải) dựa vào isMe
    if (message.isMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(
              left: 64.0, right: 8.0, top: 4.0, bottom: 4.0),
          child: placeholderWidget,
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 4.0),
              child: CircleAvatar(
                backgroundImage: AssetImage(_currentUserAvatar),
                radius: 16,
              ),
            ),
            Expanded(
              child: placeholderWidget,
            ),
          ],
        ),
      );
    }
  }

  // Hàm cập nhật ChatBubble khi nhận được file đầy đủ
  void updateFileMessage(String fileName, ChatMessage updatedMessage) {
    if (!mounted || !_userMessages.containsKey(widget.userId)) return;

    final messages = _userMessages[widget.userId]!;
    int indexToUpdate = -1;

    // Tìm tin nhắn dựa trên tên file trong định dạng "file_path [filename] ..."
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].text.startsWith('file_path ') &&
          messages[i].text.contains(fileName)) {
        indexToUpdate = i;
        break;
      }
    }

    // Nếu tìm thấy, cập nhật tin nhắn
    if (indexToUpdate >= 0) {
      setState(() {
        // Cập nhật trong bộ nhớ cache local
        _userMessages[widget.userId]![indexToUpdate] = updatedMessage;

        // Đồng thời cập nhật trong trạng thái toàn cục
        if (widget.groupController.clientState != null &&
            widget.groupController.clientState!.allMessagesConverted
                .containsKey(widget.userId)) {
          widget.groupController.clientState!
                  .allMessagesConverted[widget.userId]![indexToUpdate] =
              updatedMessage;
        }

        // Cập nhật lại danh sách tin nhắn hiển thị
        listhistorymessage = _userMessages[widget.userId]!;

        print("Cập nhật tin nhắn file tại vị trí $indexToUpdate: $fileName");
      });
    } else {
      print("Không tìm thấy tin nhắn file với tên: $fileName");
    }
  }

  void _addToDownloadQueue(
      String chatId, String roomId, String filePath, String fileType) {
    final item = FileTransferItem(
      status: FileConstants.Action_Status_File_Download,
      currentChatId: chatId,
      userId: roomId,
      filePath: filePath,
      actualFileSize: 0,
      fileType: fileType,
      actualTotalPackages: 0,
    );

    FileTransferQueue.instance.addToQueue(item);
  }

  // Xử lý khi có thông báo cập nhật ChatBubble từ MessageNotifier
  void _handleChatBubbleUpdate() {
    if (MessageNotifier.message.value != null) {
      // Nhận tin nhắn cập nhật từ MessageNotifier
      final updatedMessage = MessageNotifier.message.value!;
      final fileName = MessageNotifier.name.value;

      if (fileName.isNotEmpty) {
        // Tìm và cập nhật tin nhắn dựa trên tên file
        updateFileMessage(fileName, updatedMessage);
      }
    }
  }
}
