// Import UserList to access the static cache
import 'package:finalltmcb/Widget/AudioRecorderWidget.dart';
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

  // Add a flag to track if we're currently recording
  bool _isRecording = false;

  // Thêm biến để theo dõi trạng thái gửi audio
  bool _isSendingAudio = false;

  // Add a state variable to track if the add button menu is showing
  bool _isAddMenuVisible = false;

  // Add a OverlayEntry để quản lý menu
  OverlayEntry? _overlayEntry;

  // Create a GlobalKey to track the Add button's position precisely
  final GlobalKey _addButtonKey = GlobalKey();

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

  // Fetch user profile information from the static cache in UserList
  void _fetchUserProfile() {
    // Access the public static cache from MessageList.
    // Find the chat data manually to avoid orElse type issues.
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
      // Use null assertion operator (!) since we've checked chatData is not null
      setState(() {
        // Update state with fetched data
        _currentUserName = chatData!['name'] ?? 'Unknown Chat';
        _currentUserAvatar =
            chatData!['avatar'] ?? 'assets/logoS.jpg'; // Default avatar
        _isGroupChat = chatData!['isGroup'] ?? false;
        if (_isGroupChat) {
          // If it's a group, get member IDs. We need to convert them back to names if needed.
          // For now, just store the count or IDs. The AppBar uses length.
          _groupMembers = List<String>.from(chatData!['members'] ?? []);
        } else {
          _groupMembers = [];
        }
      });
    } else {
      // Handle case where chat ID is not found in the cache
      setState(() {
        _currentUserName = "Unknown Chat";
        _currentUserAvatar = "assets/logoS.jpg";
        _isGroupChat = false;
        _groupMembers = [];
      });
    }
  }

  // Improved function to handle sending messages
  Future<void> _handleSubmitted(String text) async {
    if (text.isEmpty && _selectedImages.isEmpty) {
      return; // Don't send empty messages
    }

    try {
      // First add text message if not empty
      if (text.isNotEmpty) {
        setState(() {
          if (!_userMessages.containsKey(widget.userId)) {
            _userMessages[widget.userId] = [];
          }

          _userMessages[widget.userId]!.add(ChatMessage(
            text: text,
            isMe: true,
            timestamp: DateTime.now(),
            image: null,
          ));
          _textController.clear(); // Clear the input field
        });

        // Ensure we scroll after adding the text message
        _scrollToBottom();
      }

      // Process images outside of setState without showing a snackbar
      if (_selectedImages.isNotEmpty) {
        // Process each image one by one
        for (var image in List<XFile>.from(_selectedImages)) {
          await _processAndAddImage(image);
          // Scroll after each image to ensure visibility
          _scrollToBottom();
        }

        // Clear selected images after processing
        setState(() {
          _selectedImages.clear();
        });
      }
    } catch (e) {
      print("Error sending message: $e");
      // Just print error without showing UI notification
    }
  }

  // Improved image processing with better scrolling
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

        // Update UI with the new image message
        setState(() {
          if (!_userMessages.containsKey(widget.userId)) {
            _userMessages[widget.userId] = [];
          }

          _userMessages[widget.userId]!.add(ChatMessage(
            text: '', // Empty text for image messages
            isMe: true,
            timestamp: DateTime.now(),
            image: base64Image,
          ));
        });

        // Improved scrolling call
        _scrollToBottom();
      }
    } catch (e) {
      print("Error processing image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process image: $e')),
      );
    }
  }

  // Improved helper function to scroll to bottom of chat - make more reliable
  void _scrollToBottom() {
    // Use a double-delay approach for more reliable scrolling
    // First delay ensures widget tree is updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Second delay ensures the layout has been calculated
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

  // Function to send images without text
  void _sendOnlyImages() {
    if (_selectedImages.isEmpty) return;
    _handleSubmitted('');
  }

  // Helper function to process and add image messages (deprecated, use _processAndAddImage instead)
  Future<void> _addImageMessage(XFile image) async {
    await _processAndAddImage(image);
  }

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    try {
      final ImagePicker _picker = ImagePicker();
      final List<XFile>? images = await _picker.pickMultiImage();

      if (images != null && images.isNotEmpty) {
        // We'll update this to be smoother
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _selectedImages.addAll(images);
          });
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      // Don't show SnackBar to avoid blocking the chat
      print('Failed to pick image: $e');
    }
  }

  // Function to add selected images smoothly
  void _updateSelectedImages(List<XFile> newImages) {
    setState(() {
      _selectedImages.addAll(newImages);
    });
  }

  // Function to remove an image smoothly
  void _removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      setState(() {
        _selectedImages.removeAt(index);
      });
    }
  }

  // Add this method to handle audio recording
  void _handleAudioRecording() {
    setState(() {
      _isRecording = true;
    });
  }

  // Improved audio handling function
  void _handleAudioSaved(String audioPath) {
    print("🔊 Audio saved to path: $audioPath");

    // Bắt đầu trạng thái loading
    setState(() {
      _isSendingAudio = true;
      _isRecording = false; // Kết thúc ghi âm
    });

    // Xử lý audio trong một luồng riêng để tránh block UI
    Future.microtask(() async {
      try {
        print("🔊 Adding audio message to chat...");

        // Đảm bảo path là absolute path
        final String absolutePath;
        if (kIsWeb) {
          absolutePath = audioPath;
        } else {
          // Đảm bảo có absolute path trên mobile
          final file = File(audioPath);
          absolutePath = file.absolute.path;
          print("🔊 Absolute audio path: $absolutePath");

          // Kiểm tra kích thước file
          if (await file.exists()) {
            final fileSize = await file.length();
            print("🔊 Audio file size: $fileSize bytes");

            // Nếu file quá lớn, có thể thực hiện xử lý tối ưu ở đây
            if (fileSize > 5 * 1024 * 1024) {
              // > 5MB
              print("🔊 Large audio file detected - optimizing");
              // Ở đây có thể thêm logic nén file nếu cần
            }
          }
        }

        // Tạo message mới với file path
        final newMessage = ChatMessage(
          text: '', // Empty text for audio messages
          isMe: true,
          timestamp: DateTime.now(),
          audio: absolutePath,
          isAudioPath: true, // Indicate this is a file path, not base64
        );

        // Cập nhật UI với message mới
        if (mounted) {
          setState(() {
            _isSendingAudio = false;
            // Đảm bảo userId tồn tại trong map
            if (!_userMessages.containsKey(widget.userId)) {
              _userMessages[widget.userId] = [];
            }
            _userMessages[widget.userId]!.add(newMessage);
          });

          // Improved scrolling - more reliable
          _scrollToBottom();

          // Add an extra scroll attempt after a longer delay for large audio files
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              _scrollToBottom();
            }
          });
        }

        print("🔊 Audio message added successfully");
      } catch (e) {
        print("🔊 ERROR adding audio message: $e");
        if (mounted) {
          setState(() {
            _isSendingAudio = false;
          });
        }
        _handleAudioCancel();
      }
    });
  }

  // Add this method to handle canceling recording
  void _handleAudioCancel() {
    if (mounted) {
      setState(() {
        _isRecording = false;
      });
    }
  }

  // Add method to handle image viewing in full-screen
  void _viewImage(String base64Image) {
    ImageViewerWidget.viewImage(context, base64Image);
  }

  // Improved toggle menu method with better positioning
  void _toggleAddMenu() {
    print("Toggle add menu called, current state: $_isAddMenuVisible");

    if (_isAddMenuVisible) {
      // Nếu menu đang hiển thị, đóng nó lại
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() => _isAddMenuVisible = false);
    } else {
      // Find the button position using the GlobalKey
      final RenderBox? buttonBox =
          _addButtonKey.currentContext?.findRenderObject() as RenderBox?;

      if (buttonBox == null) {
        print("Cannot find add button position");
        return;
      }

      // Calculate the position of the button in the global coordinate system
      final buttonPosition = buttonBox.localToGlobal(Offset.zero);
      final buttonSize = buttonBox.size;

      // Calculate the menu position to appear just above the button
      final double menuLeft = buttonPosition.dx;
      final double menuTop =
          buttonPosition.dy - 100; // Position just above the button

      print(
          "Button position: $buttonPosition, Menu position: ($menuLeft, $menuTop)");

      // Create and position the overlay
      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: menuLeft,
          top: menuTop,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Container(
              width: 50, // Fixed width to ensure proper sizing
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
                  // File option
                  InkWell(
                    onTap: () {
                      // Use Future.microtask to prevent UI interruption
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
                  // Video option
                  InkWell(
                    onTap: () {
                      // Use Future.microtask to prevent UI interruption
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

      // Use a try-catch to prevent app crashes if overlay insertion fails
      try {
        Overlay.of(context).insert(_overlayEntry!);
        setState(() => _isAddMenuVisible = true);
      } catch (e) {
        print("Error showing menu: $e");
        _overlayEntry = null;
      }
    }
  }

  // Add methods to handle file/video sending (stub implementations for now)
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
      // Step 1: Let user pick a file without showing a snackbar
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: kIsWeb, // Only load file data on web
        dialogTitle: 'Select a file to share',
      );

      // Reset processing flag
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

      // Add the file message to chat
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

    if (_isProcessingFile) {
      print("Already processing a file/video, ignoring request");
      return;
    }

    // Set processing flag
    setState(() => _isProcessingFile = true);

    try {
      // Pick video from gallery
      final ImagePicker picker = ImagePicker();

      // Show a small loading indicator
      _showTopNotification("Đang mở chọn video...",
          isInfo: true, duration: Duration(seconds: 1));

      final XFile? pickedVideo = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10), // Increased max duration
      );

      if (pickedVideo == null) {
        setState(() => _isProcessingFile = false);
        print("No video selected or selection canceled");
        return;
      }

      print("Selected video: ${pickedVideo.path}");

      // Lưu video vào thư mục ứng dụng để xử lý sau này
      final String savedVideoPath = await _saveVideoToAppDirectory(pickedVideo);
      print("Video saved to: $savedVideoPath");

      // Add a loading placeholder message immediately
      setState(() {
        if (!_userMessages.containsKey(widget.userId)) {
          _userMessages[widget.userId] = [];
        }

        _userMessages[widget.userId]!.add(ChatMessage(
          text: '',
          isMe: true,
          timestamp: DateTime.now(),
          video: savedVideoPath, // Use the saved path for persistence
          isVideoLoading: true, // Show as loading
        ));
      });

      // Scroll to show the loading message
      _scrollToBottom();

      // Process the video in background
      Future.microtask(() async {
        try {
          // For large videos, show a processing message
          if (!kIsWeb) {
            try {
              final File videoFile = File(savedVideoPath);
              if (await videoFile.exists()) {
                final fileSize = await videoFile.length();
                print("Video file size: $fileSize bytes");

                if (fileSize > 10 * 1024 * 1024) {
                  // > 10MB
                  _showTopNotification(
                      "Đang xử lý video lớn (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB)...",
                      isInfo: true,
                      duration: Duration(seconds: 3));

                  // Simulate processing time for large files
                  await Future.delayed(Duration(milliseconds: 1500));
                }
              }
            } catch (e) {
              print("Error checking video file size: $e");
            }
          }

          // Update the message with processed video
          if (mounted) {
            setState(() {
              // Find the loading message and replace it
              final messages = _userMessages[widget.userId] ?? [];
              for (int i = messages.length - 1; i >= 0; i--) {
                final msg = messages[i];
                if (msg.isVideoMessage &&
                    msg.isVideoLoading &&
                    msg.video == savedVideoPath) {
                  messages[i] = ChatMessage(
                    text: '',
                    isMe: true,
                    timestamp: msg.timestamp,
                    video: savedVideoPath,
                    isVideoLoading: false, // No longer loading
                  );
                  break;
                }
              }
              _isProcessingFile = false;
            });

            // Scroll to show the updated message
            _scrollToBottom();
          }
        } catch (e) {
          print("Error processing video: $e");
          if (mounted) {
            setState(() => _isProcessingFile = false);
            _showTopNotification(
                "Lỗi xử lý video: ${e.toString().split('\n').first}",
                isError: true);
          }
        }
      });
    } catch (e) {
      print("Error handling video: $e");
      setState(() => _isProcessingFile = false);
      _showTopNotification("Lỗi chọn video: ${e.toString().split('\n').first}",
          isError: true);
    }
  }

  // Hàm lưu video vào thư mục ứng dụng để xử lý sau này
  Future<String> _saveVideoToAppDirectory(XFile videoFile) async {
    try {
      print("Saving video to app directory: ${videoFile.path}");

      // Lấy thư mục ứng dụng
      final appDir = await getApplicationDocumentsDirectory();

      // Tạo thư mục videos nếu chưa có
      final videosDir = Directory('${appDir.path}/videos');
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }

      // Đảm bảo tên file độc nhất
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(videoFile.path).toLowerCase();
      final validExtension =
          ['.mp4', '.mov', '.avi', '.mkv', '.wmv', '.3gp'].contains(extension)
              ? extension
              : '.mp4';

      final newFileName = 'video_${timestamp}$validExtension';

      // Đường dẫn đích - đảm bảo format đường dẫn
      final destinationPath =
          path.join(videosDir.path, newFileName).replaceAll('\\', '/');

      print("Video will be saved to: $destinationPath");

      try {
        // Đọc file gốc
        final bytes = await videoFile.readAsBytes();
        print("Read ${bytes.length} bytes from source video");

        // Viết vào file đích
        final File newFile = File(destinationPath);
        await newFile.writeAsBytes(bytes);

        // Kiểm tra file đã được tạo
        if (await newFile.exists()) {
          final fileSize = await newFile.length();
          print("Successfully saved video (${fileSize} bytes)");
          return destinationPath;
        } else {
          print("Failed to create video file at destination");
          return videoFile.path;
        }
      } catch (e) {
        print("Error copying video file: $e");

        // Fallback to copy method if writeAsBytes fails
        try {
          final File sourceFile = File(videoFile.path);
          final File newFile = await sourceFile.copy(destinationPath);

          if (await newFile.exists()) {
            print("Copied video file successfully using File.copy()");
            return destinationPath;
          }
        } catch (e2) {
          print("Error with fallback copy: $e2");
        }

        return videoFile.path;
      }
    } catch (e) {
      print("Error in _saveVideoToAppDirectory: $e");
      return videoFile.path;
    }
  }

  // Đảm bảo đóng overlay khi widget bị dispose
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
            // Use a Key based on userId to force AppBar rebuild when user changes
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
                      // Display member count based on the length of the members list (IDs)
                      "${_groupMembers.length} members",
                      style: TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
            // Show Call and Video Call icons for both individual and group chats
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
                    // Add padding at the bottom to ensure messages aren't hidden behind input
                    padding: EdgeInsets.only(bottom: 16),
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      if (message.isMe) {
                        // Pass the file download handler to ChatBubble
                        return ChatBubble(
                          message: message,
                          onFileDownload: _handleFileDownload,
                        );
                      } else {
                        // Other user's message - include avatar
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar for other users
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 4.0),
                                child: CircleAvatar(
                                  backgroundImage:
                                      AssetImage(_currentUserAvatar),
                                  radius: 16,
                                ),
                              ),
                              // Message bubble - with file download handler
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

  // Update the _buildChatInput method to show AudioRecorderWidget when recording
  Widget _buildChatInput() {
    if (_isRecording) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: AudioRecorderWidget(
          onAudioSaved: _handleAudioSaved,
          onCancel: _handleAudioCancel,
        ),
      );
    }

    if (_isSendingAudio) {
      // Hiển thị loading khi đang xử lý audio
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.red),
              SizedBox(height: 8),
              Text(
                "Đang xử lý audio...",
                style: TextStyle(color: Colors.red.shade700),
              ),
            ],
          ),
        ),
      );
    }

    // Existing chat input UI for normal mode
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Replace the image preview with our ImagesPreviewWidget
          ImagesPreviewWidget(
            images: _selectedImages,
            onRemove: _removeImage,
          ),
          Stack(
            children: [
              // Main input row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Replace the add button with our new implementation
                  IconButton(
                    key: _addButtonKey,
                    onPressed: () {
                      print("Add button pressed");
                      _toggleAddMenu();
                    },
                    icon: const Icon(
                      Icons.add,
                      color: Colors.red,
                    ),
                  ),
                  // Rest of the row - text field, image and mic buttons
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
                  // Replace the image button with our new widget
                  ImagePickerButtonWidget(
                    onImagesSelected: (List<XFile> images) {
                      setState(() {
                        _selectedImages.addAll(images);
                      });
                    },
                    iconColor: Colors.red,
                  ),
                  IconButton(
                      onPressed:
                          _handleAudioRecording, // Connect to the audio recording handler
                      icon: const Icon(
                        Icons.mic,
                        color: Colors.red,
                      )),
                  // Smart send button - handles both text and images
                  IconButton(
                      onPressed: () {
                        // If there's text or images or both, send them
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

  // Creating a separate widget for image preview for better maintainability
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
