// Import UserList to access the static cache
import 'package:finalltmcb/Model/AudioMessage.dart';
import 'package:finalltmcb/Model/MessageData.dart';
import 'package:finalltmcb/Widget/AudioHandlerWidget.dart'; // Import the new widget
import 'package:finalltmcb/Widget/UserList.dart';
import 'package:finalltmcb/Model/ChatMessage.dart';
import 'package:finalltmcb/Model/AudioMessage.dart';
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

  // Controller for the text input field
  final TextEditingController _textController = TextEditingController();

  // List to store selected images
  List<XFile> _selectedImages = [];

  // ScrollController for ListView
  final ScrollController _scrollController = ScrollController();

  // Add a state variable to track if the add button menu is showing
  bool _isAddMenuVisible = false;

  // Add a state variable to know if the AudioHandlerWidget is active (recording/sending)
  bool _isAudioHandlerActive = false;

  // Add a OverlayEntry để quản lý menu
  OverlayEntry? _overlayEntry;

  // Create a GlobalKey to track the Add button's position precisely
  final GlobalKey _addButtonKey = GlobalKey();

  // Add a flag to track if a file is being processed
  bool _isProcessingFile = false;

  // Add this field to hold our media handler instance
  late MediaHandlerWidget _mediaHandler;

  @override
  void initState() {
    super.initState();
    _loadUserMessages();

    _mediaHandler = MediaHandlerWidget(
      context: context,
      onMessageCreated: _handleMessageCreated, // Pass the handler
      userId: widget.userId,
      onProcessingStart: () => setState(() => _isProcessingFile = true),
      onProcessingEnd: () => setState(() => _isProcessingFile = false),
      onError: _showTopNotification,
    );
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
      _userMessages[widget.userId] = [
        ChatMessage(
          text: 'Hello!',
          isMe: true,
          timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          image: null,
        ),
        ChatMessage(
          text: 'Hi there!',
          isMe: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
          image: null,
        ),
        ChatMessage(
          text: 'How are you doing?',
          isMe: true,
          timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
          image: null,
        ),
        ChatMessage(
          text: 'I\'m doing great! Thanks for asking.',
          isMe: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          image: null,
        ),
      ];
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

  Future<ImageMessage?> _convertImageToBase64(XFile image) async {
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
      return null;
    }
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.isEmpty && _selectedImages.isEmpty) return;

    final timestamp = DateTime.now();
    List<ImageMessage> processedImages = [];
    List<ChatMessage> uiMessagesToAdd = []; // Messages to add to UI

    // --- Prepare UI Messages ---
    try {
      // 1. Prepare text message for UI
      if (text.isNotEmpty) {
        uiMessagesToAdd.add(ChatMessage(
          text: text,
          isMe: true,
          timestamp: timestamp,
        ));
      }

      // 2. Process images and prepare image messages for UI
      if (_selectedImages.isNotEmpty) {
        print('Processing ${_selectedImages.length} images for send...');
        for (var image in List<XFile>.from(_selectedImages)) {
          ImageMessage? imgMsg = await _convertImageToBase64(image);
          if (imgMsg != null) {
            processedImages.add(imgMsg);
            // Create a ChatMessage for each image for the UI
            uiMessagesToAdd.add(ChatMessage(
              text: '',
              isMe: true,
              timestamp: timestamp,
              image: imgMsg.base64Data, // Store base64 for UI bubble
              mimeType: imgMsg.mimeType,
            ));
          }
        }
        print('Processed ${processedImages.length} images.');
      }

      if (uiMessagesToAdd.isEmpty) return; // Nothing to add or send

      // --- Update UI Immediately ---
      setState(() {
        if (!_userMessages.containsKey(widget.userId)) {
          _userMessages[widget.userId] = [];
        }
        _userMessages[widget.userId]!.addAll(uiMessagesToAdd);
        _textController.clear();
        _selectedImages.clear();
      });
      _scrollToBottom();

      // --- Send Message in Background ---
      Future(() async {
        try {
          // Create MessageData containing only data to be sent
          final messageDataToSend = MessageData(
            text: text.isNotEmpty ? text : null,
            images: processedImages, // Send processed images
            audios: [],
            files: [],
            video: null,
            timestamp: timestamp,
          );

          _logMessageDataForServer(messageDataToSend); // Log before sending

          print(
              "Attempting to send Text/Image message via Controller/CommandProcessor...");
          // Use widget.userId as roomId, adjust if necessary
          await MessageController().SendMessage(messageDataToSend);
          print(
              "Text/Image message processing initiated via Controller/CommandProcessor.");
          // Optional: Update message status in UI to 'sent' or 'delivered' later based on ACK
        } catch (sendError, stackTrace) {
          logger.log(
              "Error sending Text/Image message in background: $sendError",
              name: "ChatContent",
              error: sendError,
              stackTrace: stackTrace);
          // Optional: Update message status in UI to 'failed'
          _showTopNotification('Lỗi gửi tin nhắn', isError: true);
        }
      });
    } catch (e, stackTrace) {
      logger.log("Error preparing submitted message: $e",
          name: "ChatContent", error: e, stackTrace: stackTrace);
      _showTopNotification('Có lỗi xảy ra khi xử lý tin nhắn', isError: true);
    }
  }

  Future<void> _processAndAddImage(XFile image) async {
    try {
      String base64Image;

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        base64Image = base64Encode(bytes);
        print('Web image path: ${image.path}');
      } else {
        File imageFile = File(image.path);
        print('Native image path: ${image.path}');
        final bytes = await imageFile.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      if (base64Image.isNotEmpty) {
        print(
            'Base64 image (first 50 chars): ${base64Image.substring(0, math.min(50, base64Image.length))}...');

        setState(() {
          if (!_userMessages.containsKey(widget.userId)) {
            _userMessages[widget.userId] = [];
          }

          _userMessages[widget.userId]!.add(ChatMessage(
            text: '',
            isMe: true,
            timestamp: DateTime.now(),
            image: base64Image,
          ));
        });

        _scrollToBottom();
      }
    } catch (e) {
      print("Error processing image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process image: $e')),
      );
    }
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

  void _sendOnlyImages() {
    if (_selectedImages.isEmpty) return;
    _handleSubmitted('');
  }

  Future<void> _addImageMessage(XFile image) async {
    await _processAndAddImage(image);
  }

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    try {
      final ImagePicker _picker = ImagePicker();
      final List<XFile>? images = await _picker.pickMultiImage();

      if (images != null && images.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _selectedImages.addAll(images);
          });
        });
      }
    } catch (e) {}
  }

  void _updateSelectedImages(List<XFile> newImages) {
    setState(() {
      _selectedImages.addAll(newImages);
    });
  }

  void _removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      setState(() {
        _selectedImages.removeAt(index);
      });
    }
  }

  // First add this class to properly handle audio data

// Update the _handleAudioMessageSent method
  Future<void> _handleAudioMessageSent(ChatMessage message) async {
    logger.log("Handling sent audio message (UI Update): ${message.toJson()}",
        name: "ChatContent");

    if (!mounted) return;

    // --- Update UI Immediately ---
    setState(() {
      if (!_userMessages.containsKey(widget.userId)) {
        _userMessages[widget.userId] = [];
      }
      // Add the ChatMessage as received from AudioHandlerWidget
      _userMessages[widget.userId]!.add(message);
      _isAudioHandlerActive = false; // Assume audio handler is done
    });
    _scrollToBottom();

    // --- Process and Send in Background ---
    Future(() async {
      try {
        AudioData? audioData;
        // Re-process audio to get AudioData object for sending
        if (message.isAudioPath && message.audio != null) {
          final File audioFile = File(message.audio!);
          final bytes = await audioFile.readAsBytes();
          audioData = AudioData(
            base64Data: base64Encode(bytes),
            duration: 0, // TODO: Get actual duration if possible
            mimeType: lookupMimeType(message.audio!) ?? 'audio/mp4',
            size: bytes.length,
          );
        } else if (message.audio != null) {
          final bytes = base64Decode(message.audio!);
          audioData = AudioData(
            base64Data: message.audio!,
            duration: 0, // TODO: Get actual duration if possible
            mimeType: 'audio/mp4', // Assume mp4 if only base64 is provided
            size: bytes.length,
          );
        } else {
          logger.log(
              'Warning: No valid audio data found in ChatMessage for background sending.',
              name: "ChatContent");
          return; // Cannot send
        }

        final messageDataToSend = MessageData(
          text: null,
          images: [],
          audios: [audioData],
          files: [],
          video: null,
          timestamp: message.timestamp,
        );

        _logMessageDataForServer(messageDataToSend);

        print(
            "Attempting to send Audio message via Controller/CommandProcessor...");
        // Use widget.userId as roomId, adjust if necessary
        await MessageController().SendMessage(messageDataToSend);
        print(
            "Audio message processing initiated via Controller/CommandProcessor.");
        // Optional: Update message status in UI
      } catch (sendError, stackTrace) {
        logger.log("Error sending Audio message in background: $sendError",
            name: "ChatContent", error: sendError, stackTrace: stackTrace);
        // Optional: Update message status in UI to 'failed'
        _showTopNotification('Lỗi gửi âm thanh', isError: true);
      }
    });
  }

  void _viewImage(String base64Image) {
    ImageViewerWidget.viewImage(context, base64Image);
  }

  void _toggleAddMenu() {
    print("Toggle add menu called, current state: $_isAddMenuVisible");

    if (_isAddMenuVisible) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() => _isAddMenuVisible = false);
    } else {
      final RenderBox? buttonBox =
          _addButtonKey.currentContext?.findRenderObject() as RenderBox?;

      if (buttonBox == null) {
        print("Cannot find add button position");
        return;
      }

      final buttonPosition = buttonBox.localToGlobal(Offset.zero);
      final buttonSize = buttonBox.size;

      final double menuLeft = buttonPosition.dx;
      final double menuTop = buttonPosition.dy - 100;

      print(
          "Button position: $buttonPosition, Menu position: ($menuLeft, $menuTop)");

      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: menuLeft,
          top: menuTop,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Container(
              width: 50,
              padding: EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      print("--- _handleFileSend ENTERED ---");
                      Future.microtask(() => _handleFileSend());
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.insert_drive_file,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                  ),
                  Divider(height: 1, thickness: 1),
                  InkWell(
                    onTap: () {
                      Future.microtask(() => _handleVideoSend());
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.videocam,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        Overlay.of(context).insert(_overlayEntry!);
        setState(() => _isAddMenuVisible = true);
      } catch (e) {
        print("Error showing menu: $e");
        _overlayEntry = null;
      }
    }
  }

  // This handles messages created by MediaHandlerWidget (File/Video)
  // Keep async for potential background processing
  Future<void> _handleMessageCreated(ChatMessage message) async {
    logger.log(
        "Handling created media message (UI Update): ${message.toJson()}",
        name: "ChatContent");

    if (mounted) {
      // --- Update UI Immediately ---
      setState(() {
        if (!_userMessages.containsKey(widget.userId)) {
          _userMessages[widget.userId] = [];
        }
        // Add the ChatMessage containing FileMessage or VideoFileMessage
        _userMessages[widget.userId]!.add(message);
      });
      _scrollToBottom();

      // --- Create MessageData and Send in Background ---
      Future(() async {
        try {
          MessageData? messageDataToSend; // Nullable

          if (message.file != null) {
            // Ensure FileMessage has bytes if needed for sending (depends on FileMessage.toJson)
            messageDataToSend = MessageData(
                text: null,
                images: [],
                audios: [],
                files: [message.file!],
                video: null,
                timestamp: message.timestamp);
          } else if (message.video != null) {
            messageDataToSend = MessageData(
                text: null,
                images: [],
                audios: [],
                files: [],
                video: message.video,
                timestamp: message.timestamp);
          } else {
            logger.log(
                'Warning: _handleMessageCreated called with ChatMessage containing neither file nor video.',
                name: "ChatContent");
            return; // Nothing specific to send in this context
          }

          _logMessageDataForServer(messageDataToSend);

          print(
              "Attempting to send File/Video message via Controller/CommandProcessor...");
          // Use widget.userId as roomId, adjust if necessary
          await MessageController().SendMessage(messageDataToSend);
          print(
              "File/Video message processing initiated via Controller/CommandProcessor.");
          // Optional: Update message status in UI
        } catch (sendError, stackTrace) {
          logger.log(
              "Error sending File/Video message in background: $sendError",
              name: "ChatContent",
              error: sendError,
              stackTrace: stackTrace);
          // Optional: Update message status in UI to 'failed'
          _showTopNotification('Lỗi gửi tệp đính kèm', isError: true);
        }
      });
    }
  }

  // Keep async for file picking, but separate UI and sending
  Future<void> _handleFileSend() async {
    print("Initiating file send...");
    _toggleAddMenu(); // Close menu if open

    if (_isProcessingFile) {
      print("⚠️ Already processing a file, ignoring request");
      return;
    }
    setState(() => _isProcessingFile = true);

    FileMessage? fileMessageForSend; // To hold data for background task
    ChatMessage? uiChatMessage; // To hold message for UI
    final timestamp = DateTime.now();

    try {
      // --- Pick File ---
      print("\n📂 Opening file picker...");
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true, // Ensure bytes are loaded if possible
        dialogTitle: 'Select a file to share',
      );

      if (result == null || result.files.isEmpty) {
        print("❌ No file selected");
        setState(() => _isProcessingFile = false);
        return;
      }
      final file = result.files.first;

      // --- Process File Data ---
      Uint8List? fileBytes = file.bytes;
      if (fileBytes == null && file.path != null && !kIsWeb) {
        try {
          fileBytes = await File(file.path!).readAsBytes();
        } catch (e) {
          print("❌ Error reading file bytes from path: $e");
          _showTopNotification('Error reading file data', isError: true);
          setState(() => _isProcessingFile = false);
          return;
        }
      }
      if (fileBytes == null) {
        print("❌ File bytes are null, cannot proceed.");
        _showTopNotification('Could not load file data', isError: true);
        setState(() => _isProcessingFile = false);
        return;
      }

      // --- Create FileMessage and ChatMessage for UI ---
      fileMessageForSend = FileMessage(
        fileName: file.name,
        mimeType: lookupMimeType(file.name,
                headerBytes: fileBytes.take(1024).toList()) ??
            FilePickerUtil.getMimeType(file.name),
        fileSize: fileBytes.length,
        filePath: file.path ?? '',
        fileBytes: fileBytes, // Include bytes
      );
      uiChatMessage = ChatMessage(
        text: '',
        isMe: true,
        timestamp: timestamp,
        file: fileMessageForSend, // Pass the full FileMessage
      );

      // --- Update UI Immediately ---
      setState(() {
        if (!_userMessages.containsKey(widget.userId)) {
          _userMessages[widget.userId] = [];
        }
        _userMessages[widget.userId]!
            .add(uiChatMessage!); // Add message to list
      });
      _scrollToBottom();
      print("\n✅ File message added to UI.");

      // --- Send Message in Background ---
      Future(() async {
        try {
          final messageDataToSend = MessageData(
            text: null,
            images: [],
            audios: [],
            files: [fileMessageForSend!], // Send the processed file message
            video: null,
            timestamp: timestamp,
          );

          _logMessageDataForServer(messageDataToSend);

          print(
              "Attempting to send File message via Controller/CommandProcessor...");
          // Use widget.userId as roomId, adjust if necessary
          await MessageController().SendMessage(messageDataToSend);
          print(
              "File message processing initiated via Controller/CommandProcessor.");
          // Optional: Update message status in UI
        } catch (sendError, stackTrace) {
          logger.log("Error sending File message in background: $sendError",
              name: "ChatContent", error: sendError, stackTrace: stackTrace);
          // Optional: Update message status in UI to 'failed'
          _showTopNotification('Lỗi gửi tệp', isError: true);
        }
      });
    } catch (e, stackTrace) {
      logger.log("\n❌ Error handling file selection/processing: $e",
          name: "ChatContent", error: e, stackTrace: stackTrace);
      _showTopNotification('Lỗi xử lý tệp', isError: true);
    } finally {
      // Set processing to false after picking and UI update, background send continues independently
      if (mounted) {
        setState(() => _isProcessingFile = false);
      }
      print("\n========== END FILE SEND HANDLING (UI part) ==========");
    }
  }

  // Thêm lại hàm này để xử lý nút chọn video
  void _handleVideoSend() async {
    logger.log("Video send button tapped, delegating to MediaHandler...",
        name: "ChatContent");
    _toggleAddMenu(); // Close the menu

    if (_isProcessingFile) {
      logger.log("⚠️ Already processing a file/video, ignoring video request",
          name: "ChatContent");
      _showTopNotification("Đang xử lý tệp khác...", isInfo: true);
      return;
    }
    // Let MediaHandlerWidget pick the video and call _handleMessageCreated via its callback
    await _mediaHandler.handleVideoSend();
  }

  // Utility function to log MessageData before sending to server
  void _logMessageDataForServer(MessageData messageData) {
    try {
      final jsonData = messageData.toJson();

      // Truncate large base64 data for logging
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
            // Assuming FileMessage encodes bytes to 'fileData'
            file['fileData'] =
                '${(file['fileData'] as String).substring(0, math.min(50, (file['fileData'] as String).length))}... (truncated)';
          }
          if (file['fileBytes'] != null) {
            // Remove raw bytes if they were included somehow
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

      // TODO: Implement actual server sending logic here
      // Example: await ApiService.sendMessage(messageData);
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
    // Close any open menu
    if (_isAddMenuVisible) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
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
                onPressed: () {/* TODO: Implement call action */},
                icon: Icon(Icons.call)),
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
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    if (_isAudioHandlerActive) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey)),
        ),
        child: AudioHandlerWidget(
          showRecorder: _isAudioHandlerActive, // Control visibility
          onAudioMessageSent: _handleAudioMessageSent,
          onRecordingStart: () {
            if (mounted) {
              setState(() => _isAudioHandlerActive = true);
            }
          },
          onRecordingEnd: () {
            if (mounted) {
              setState(() => _isAudioHandlerActive = false);
            }
          },
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ImagesPreviewWidget(
            images: _selectedImages,
            onRemove: _removeImage,
          ),
          Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AttachmentMenuWidget(
                    onFileSelected: _mediaHandler.handleFileSend,
                    onVideoSelected: _mediaHandler.handleVideoSend,
                    iconColor: Colors.red,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(25)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Aa',
                          ),
                          onSubmitted: _handleSubmitted,
                        ),
                      ),
                    ),
                  ),
                  ImagePickerButtonWidget(
                    onImagesSelected: (List<XFile> images) {
                      setState(() {
                        _selectedImages.addAll(images);
                      });
                    },
                    iconColor: Colors.red,
                  ),
                  AudioHandlerWidget(
                    showRecorder: false, // Always show button here
                    onAudioMessageSent:
                        _handleMessageCreated, // Still need this
                    onRecordingStart: () {
                      if (mounted) {
                        setState(() => _isAudioHandlerActive =
                            true); // Show the recorder UI
                      }
                    },
                    onRecordingEnd: () {
                      if (mounted) {
                        setState(() => _isAudioHandlerActive = false);
                      }
                    },
                  ),
                  IconButton(
                      onPressed: () {
                        if (_textController.text.isNotEmpty ||
                            _selectedImages.isNotEmpty) {
                          _handleSubmitted(_textController.text);
                        }
                      },
                      icon: const Icon(
                        Icons.send,
                        color: Colors.red,
                      )),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImages() {
    if (_selectedImages.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb
                      ? Image.network(
                          _selectedImages[index].path,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(_selectedImages[index].path),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImages.removeAt(index);
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
