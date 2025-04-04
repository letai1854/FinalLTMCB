// Import UserList to access the static cache
import 'package:finalltmcb/Widget/AudioHandlerWidget.dart'; // Import the new widget
import 'package:finalltmcb/Widget/UserList.dart';
import 'package:finalltmcb/Model/ChatMessage.dart';
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
import 'package:mime/mime.dart';

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

    // Initialize the media handler with simplified message support
    _mediaHandler = MediaHandlerWidget(
      context: context,
      onMessageCreated: _handleMessageCreated,
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

    try {
      List<ImageMessage> processedImages = [];
      DateTime timestamp = DateTime.now();

      // Process images
      if (_selectedImages.isNotEmpty) {
        print('Processing ${_selectedImages.length} images...');

        for (var image in List<XFile>.from(_selectedImages)) {
          ImageMessage? imgMsg = await _convertImageToBase64(image);
          if (imgMsg != null) {
            processedImages.add(imgMsg);
          }
        }

        print('Successfully processed ${processedImages.length} images');
      }

      // Create message data
      final messageData = MessageData(
        text: text.isNotEmpty ? text : null,
        images: processedImages,
        timestamp: timestamp,
      );

      // Log message details
      print('\nPreparing to send message:');
      print('Text: ${messageData.text ?? "No text"}');
      print('Number of images: ${messageData.images.length}');
      for (var i = 0; i < messageData.images.length; i++) {
        print('\nImage $i:');
        print('Size: ${messageData.images[i].size} bytes');
        print('Type: ${messageData.images[i].mimeType}');
      }
      print(
          'Total message size: ${jsonEncode(messageData.toJson()).length} bytes');

      // Add to UI
      setState(() {
        if (!_userMessages.containsKey(widget.userId)) {
          _userMessages[widget.userId] = [];
        }

        // Add text if present
        if (text.isNotEmpty) {
          _userMessages[widget.userId]!.add(ChatMessage(
            text: text,
            isMe: true,
            timestamp: timestamp,
            image: null,
          ));
        }

        // Add images
        for (var img in processedImages) {
          _userMessages[widget.userId]!.add(ChatMessage(
            text: '',
            isMe: true,
            timestamp: timestamp,
            image: img.base64Data,
            mimeType: img.mimeType,
          ));
        }

        _textController.clear();
        _selectedImages.clear();
      });

      _scrollToBottom();
    } catch (e) {
      print("Error sending message: $e");
      _showTopNotification('Failed to send message', isError: true);
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
  void _handleAudioMessageSent(ChatMessage message) async {
    if (!mounted) return;

    try {
      // Convert audio path/content to base64 if needed
      AudioData audioData;

      if (message.isAudioPath && message.audio != null) {
        // If audio is stored as a file path
        final File audioFile = File(message.audio!);
        final bytes = await audioFile.readAsBytes();
        audioData = AudioData(
          audioBase64: base64Encode(bytes),
          duration: 0, // You might want to get actual duration
          mimeType: 'audio/mp4',
          fileSize: bytes.length,
        );
      } else if (message.audio != null) {
        // If audio is already in base64
        audioData = AudioData(
          audioBase64: message.audio!,
          duration: 0,
          mimeType: 'audio/mp4',
          fileSize: base64Decode(message.audio!).length,
        );
      } else {
        throw Exception('No audio data found in message');
      }

      // Create AudioMessage with the processed data
      final audioMessage = AudioMessage(
        base64Data: audioData.audioBase64,
        duration: audioData.duration,
        mimeType: audioData.mimeType,
        size: audioData.fileSize,
      );

      // Create message data
      final messageData = MessageData(
        text: null,
        images: [],
        audios: [audioMessage],
        timestamp: DateTime.now(),
      );

      // Update UI
      setState(() {
        if (!_userMessages.containsKey(widget.userId)) {
          _userMessages[widget.userId] = [];
        }
        _userMessages[widget.userId]!.add(message);
        _isAudioHandlerActive = false;
      });

      // Print debug info
      print('Audio Message Details:');
      print('Size: ${audioMessage.size} bytes');
      print('Duration: ${audioMessage.duration}ms');
      print('MIME Type: ${audioMessage.mimeType}');
      print(
          'Base64 Preview: ${audioMessage.base64Data.substring(0, math.min(50, audioMessage.base64Data.length))}...');

      // Async processing for server upload
      Future.microtask(() async {
        try {
          // TODO: Add your server upload logic here
          print("Processing audio message:");
          print(jsonEncode(messageData.toJson()));

          _scrollToBottom();
        } catch (e) {
          print("Error processing audio message: $e");
          if (mounted) {
            _showTopNotification('Failed to process audio message',
                isError: true);
          }
        }
      });
    } catch (e) {
      print("Error handling audio message: $e");
      if (mounted) {
        _showTopNotification('Error handling audio message', isError: true);
      }
    }
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

  Future<void> _handleFileSend() async {
    print("File send button clicked");
    _toggleAddMenu(); // Close menu immediately

    if (_isProcessingFile) {
      print("Already processing a file, ignoring request");
      return;
    }

    // Set processing flag
    setState(() => _isProcessingFile = true);

    // Không hiển thị thông báo Snackbar khi chọn file
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: kIsWeb, // Only load file data on web
        dialogTitle: 'Select a file to share',
      );

      setState(() => _isProcessingFile = false);

      if (result == null || result.files.isEmpty) {
        print("No file selected or selection canceled");
        return;
      }

      final file = result.files.first;
      print("Selected file: ${file.name}, size: ${file.size} bytes");

      // Create file message from result
      final fileMessage = FileMessage(
        fileName: file.name,
        mimeType: FilePickerUtil.getMimeType(
            file.name), // Changed from _getMimeType to getMimeType
        fileSize: file.size,
        filePath: file.path ?? '',
        fileBytes: file.bytes,
      );

      setState(() {
        if (!_userMessages.containsKey(widget.userId)) {
          _userMessages[widget.userId] = [];
        }

        _userMessages[widget.userId]!.add(ChatMessage(
          text: '', // Empty text for file messages
          isMe: true,
          timestamp: DateTime.now(),
          file: fileMessage,
        ));
      });

      // Scroll to bottom to show the new message
      _scrollToBottom();

      // Add an extra scroll attempt for reliability
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) _scrollToBottom();
      });
    } catch (e) {
      print("Error handling file: $e");
      setState(() => _isProcessingFile = false);

      // Chỉ hiển thị thông báo lỗi ngắn gọn nếu cần thiết
      _showTopNotification(
          'Không thể chọn file: ${e.toString().split('\n').first}');
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

  void _handleVideoSend() async {
    print("Video send button clicked");
    _toggleAddMenu(); // Close menu immediately

    // Delegate to the media handler
    await _mediaHandler.handleVideoSend();
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

  void _handleMessageCreated(ChatMessage message) {
    if (mounted) {
      setState(() {
        if (!_userMessages.containsKey(widget.userId)) {
          _userMessages[widget.userId] = [];
        }
        _userMessages[widget.userId]!.add(message);
      });

      _scrollToBottom();

      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          _scrollToBottom();
        }
      });
      print("Message added to chat: ${message.timestamp}");
    }
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

class AudioMessage {
  final String base64Data;
  final int duration;
  final String mimeType;
  final int size;

  AudioMessage({
    required this.base64Data,
    required this.duration,
    required this.mimeType,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
        'base64Data': base64Data,
        'duration': duration,
        'mimeType': mimeType,
        'size': size,
      };
}

// Add this class to handle image data
class ImageMessage {
  final String base64Data;
  final String mimeType;
  final int size;

  ImageMessage({
    required this.base64Data,
    required this.mimeType,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
        'base64Data': base64Data,
        'mimeType': mimeType,
        'size': size,
      };
}

class AudioData {
  final String audioBase64;
  final int duration;
  final String mimeType;
  final int fileSize;

  AudioData({
    required this.audioBase64,
    required this.duration,
    required this.mimeType,
    required this.fileSize,
  });
}

// Modify MessageData class
class MessageData {
  final String? text;
  final List<ImageMessage> images;
  final List<AudioMessage> audios; // Add audio support
  final DateTime timestamp;

  MessageData({
    this.text,
    List<ImageMessage>? images,
    List<AudioMessage>? audios,
    required this.timestamp,
  })  : images = images ?? [],
        audios = audios ?? [];

  Map<String, dynamic> toJson() => {
        'text': text,
        'images': images.map((img) => img.toJson()).toList(),
        'audios': audios.map((audio) => audio.toJson()).toList(),
        'timestamp': timestamp.toIso8601String(),
      };
}
