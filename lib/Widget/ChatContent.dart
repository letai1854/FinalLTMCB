// Import UserList to access the static cache
import 'package:finalltmcb/Widget/UserList.dart';
import 'package:finalltmcb/Model/ChatMessage.dart';
import 'package:finalltmcb/Widget/ChatBubble.dart';
import 'package:flutter/material.dart';

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
        ),
        ChatMessage(
          text: 'Hi there!',
          isMe: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        ),
        ChatMessage(
          text: 'How are you doing?',
          isMe: true,
          timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        ),
        ChatMessage(
          text: 'I\'m doing great! Thanks for asking.',
          isMe: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
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
      setState(() { // Update state with fetched data
        _currentUserName = chatData!['name'] ?? 'Unknown Chat';
        _currentUserAvatar = chatData!['avatar'] ?? 'assets/logoS.jpg'; // Default avatar
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
  void _handleSubmitted(String text) {
    if (text.isNotEmpty) {
      setState(() {
        _userMessages[widget.userId]!.add(ChatMessage(
          text: text,
          isMe: true,
          timestamp: DateTime.now(),
        ));
        _textController.clear(); // Clear the input field

        // Scroll to the bottom after a new message is added
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
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
            IconButton(onPressed: () { /* TODO: Implement call action */ }, icon: Icon(Icons.call)),
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
                                padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                                child: CircleAvatar(
                                  backgroundImage: AssetImage(_currentUserAvatar),
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
      child: Row(
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
              onPressed: () {},
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
          IconButton(
              onPressed: () => _handleSubmitted(_textController.text),
              icon: const Icon(
                Icons.send,
                color: Colors.red,
              )),
        ],
      ),
    );
  }
}
