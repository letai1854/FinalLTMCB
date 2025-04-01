// Import UserList to access the static cache
import 'package:finalltmcb/Widget/UserList.dart';
import 'package:finalltmcb/Model/ChatMessage.dart';
import 'dart:io';
import 'package:finalltmcb/Widget/ChatBubble.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:math' as math; // Add this import for min function

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

  // Function to handle sending messages
  Future<void> _handleSubmitted(String text) async {
    if (text.isEmpty && _selectedImages.isEmpty) {
      return; // Don't send empty messages
    }

    try {
      // First add text message if not empty
      if (text.isNotEmpty) {
        setState(() {
          _userMessages[widget.userId]!.add(ChatMessage(
            text: text,
            isMe: true,
            timestamp: DateTime.now(),
            image: null,
          ));
          _textController.clear(); // Clear the input field
        });
      }

      // Process images outside of setState without showing a snackbar
      if (_selectedImages.isNotEmpty) {
        // Process each image one by one
        for (var image in List<XFile>.from(_selectedImages)) {
          await _processAndAddImage(image);
        }

        // Clear selected images after processing
        setState(() {
          _selectedImages.clear();
        });
      }

      // Scroll to bottom after all messages are added
      _scrollToBottom();
    } catch (e) {
      print("Error sending message: $e");
      // Just print error without showing UI notification
    }
  }

  // Separate method to process and add an image to chat
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
          _userMessages[widget.userId]!.add(ChatMessage(
            text: '', // Empty text for image messages
            isMe: true,
            timestamp: DateTime.now(),
            image: base64Image,
          ));
        });

        // Force scroll to bottom after adding the image
        _scrollToBottom();
      }
    } catch (e) {
      print("Error processing image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process image: $e')),
      );
    }
  }

  // Helper function to scroll to bottom of chat
  void _scrollToBottom() {
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
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      if (message.isMe) {
                        // Current user's message - no avatar
                        return ChatBubble(message: message);
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
                              // Message bubble
                              Expanded(child: ChatBubble(message: message)),
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
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Use AnimatedSize instead of AnimatedContainer for better transitions
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Container(
              height: _selectedImages.isEmpty ? 0 : 90,
              margin:
                  EdgeInsets.only(bottom: _selectedImages.isEmpty ? 0 : 8.0),
              child: _selectedImages.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Pre-sized container to avoid layout shifts
                                Container(
                                  color: Colors.grey.shade100,
                                  width: 70,
                                  height: 70,
                                ),
                                // Image
                                kIsWeb
                                    ? Image.network(
                                        _selectedImages[index].path,
                                        fit: BoxFit.cover,
                                        width: 70,
                                        height: 70,
                                      )
                                    : Image.file(
                                        File(_selectedImages[index].path),
                                        fit: BoxFit.cover,
                                        width: 70,
                                        height: 70,
                                      ),
                                // Close button
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade700,
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
                          ),
                        );
                      },
                    ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.add,
                    color: Colors.red,
                  )),
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
              IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(
                    Icons.camera_alt,
                    color: Colors.red,
                  )),
              IconButton(
                  onPressed: () {},
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

// Create a separate widget for image preview
class ImagePreviewWidget extends StatelessWidget {
  final List<XFile> images;
  final Function(int) onRemove;

  const ImagePreviewWidget({
    Key? key,
    required this.images,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: kIsWeb
                      ? Image.network(
                          images[index].path,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(images[index].path),
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => onRemove(index),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
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
