import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MessageList extends StatefulWidget {
  final Function(String)? onUserSelected;
  final String? selectedUserId;
  final bool isDesktopOrTablet; // Add parameter to identify view type

  const MessageList({
    Key? key,
    this.onUserSelected,
    this.selectedUserId,
    this.isDesktopOrTablet = false, // Default to mobile
  }) : super(key: key);

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  // Static cache to ensure data is only loaded once across all instances
  static List<Map<String, dynamic>>? _cachedMessages;
  static bool _isLoading = false;

  // Future that will be reused for all data loading
  static Future<List<Map<String, dynamic>>>? _dataFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the future if not already created
    if (_dataFuture == null) {
      _dataFuture = _loadData();
    }

    // Listen for auto-selection only once after initial data load
    if (widget.isDesktopOrTablet && _cachedMessages != null && !_isLoading) {
      _autoSelectFirstUser();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we should auto-select the first user after data is cached
    if (widget.isDesktopOrTablet && _cachedMessages != null && !_isLoading) {
      _autoSelectFirstUser();
    }
  }

  void _autoSelectFirstUser() {
    // Only select first user if we're in desktop/tablet mode, have data,
    // no user is selected yet, and we have a callback
    if (widget.isDesktopOrTablet &&
        widget.selectedUserId == null &&
        widget.onUserSelected != null &&
        _cachedMessages != null &&
        _cachedMessages!.isNotEmpty) {
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.selectedUserId == null) {
          widget.onUserSelected!(_cachedMessages![0]['id']);
        }
      });
    }
  }
//
  Future<List<Map<String, dynamic>>> _loadData() async {
    // Return cached data if available
    if (_cachedMessages != null) {
      return _cachedMessages!;
    }

    // Prevent concurrent loading
    if (_isLoading) {
      // Wait until loading completes
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedMessages!;
    }

    _isLoading = true;

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data
      _cachedMessages = [
        {
          'name': 'Dory Family',
          'message': 'Tân: import java.io.*; import java.... 2 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '1',
          'isGroup': true, // Mark as group chat
          'members': ['You', 'Tân', 'Minh', 'Hà'],
        },
        {
          'name': 'GAME 2D/3D JOBS',
          'message': 'Anh: Em nhắn roi ạ - 2 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': false,
          'id': '2',
          'isGroup': true, // Mark as group chat
          'members': ['You', 'Anh', 'Bình', 'Cường', 'Dũng'],
        },
        {
          'name': 'Da banh ko???',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '3',
          'isGroup': true, // Mark as group chat
          'members': ['You', 'Nguyễn Minh Trường', 'Hải', 'Long'],
        },
        {
          'name': 'Mai Anh',
          'message': 'Hẹn gặp lại bạn cuối tuần nhé! 1 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '4',
          'isGroup': false,
        },
        {
          'name': 'Da banh ko???',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '5',
        },
        {
          'name': 'Da banh ko???',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '6',
        },
        {
          'name': 'Da banh ko???',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '7',
        },
        {
          'name': 'Da banh ko???',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '8',
        },
        {
          'name': 'Da banh ko???',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '9',
        },
        {
          'name': 'Da banh ko???',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '10',
        },
        {
          'name': 'Da banh ko???',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '11',
        },
        {
          'name': 'Da banh ko???',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '12',
        },
        {
          'name': 'Da banh ko???',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '13',
        },
        {
          'name': 'Da banh ko???',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '14',
        },
      ];

      // Auto-select first user only for desktop/tablet
      if (widget.isDesktopOrTablet && mounted) {
        _autoSelectFirstUser();
      }

      return _cachedMessages!;
    } finally {
      _isLoading = false;
    }
  }

  void _handleUserTap(String userId) {
    if (widget.onUserSelected != null) {
      widget.onUserSelected!(userId);
    }
  }

  void _handleCreateChat() {
    // Show dialog to create new chat
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Chat Name',
                hintText: 'Enter name for group chat',
              ),
            ),
            SizedBox(height: 16),
            Text('Select Participants:'),
            SizedBox(height: 8),
            Container(
              height: 200,
              width: double.maxFinite,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: 5, // Sample users
                itemBuilder: (context, index) {
                  return CheckboxListTile(
                    title: Text('User ${index + 1}'),
                    value: false,
                    onChanged: (value) {},
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.red,
        elevation: 0,
        title: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Tìm kiếm trên Messenger',
                icon: Icon(Icons.search),
              ),
            ),
          ),
        ),
        actions: widget.isDesktopOrTablet
            ? [
                // Desktop/tablet create chat button
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: _handleCreateChat,
                    icon: Icon(Icons.chat_bubble_outline),
                    label: Text('New Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      // Mobile floating action button for creating chats
      floatingActionButton: widget.isDesktopOrTablet
          ? null
          : FloatingActionButton(
              onPressed: _handleCreateChat,
              backgroundColor: Colors.red,
              child: Icon(Icons.chat_bubble_outline),
            ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // Use the static future to prevent rebuilding
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (snapshot.connectionState == ConnectionState.waiting &&
              _cachedMessages == null) {
            return const Center(child: CircularProgressIndicator());
          } else if ((snapshot.hasData && snapshot.data != null) ||
              _cachedMessages != null) {
            final messages = _cachedMessages ?? snapshot.data!;
            return ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isSelected = message['id'] == widget.selectedUserId;
                return ListTile(
                  selected: isSelected,
                  selectedTileColor: Colors.red.withOpacity(0.1),
                  onTap: () => _handleUserTap(message['id']),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundImage: AssetImage(message['avatar']!),
                      ),
                      // Show group indicator for group chats
                      if (message['isGroup'] == true)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Icon(
                              Icons.people,
                              size: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Text(message['name']!),
                      if (message['isGroup'] == true)
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(
                            '(${(message['members'] as List).length})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(message['message']!),
                  tileColor: Colors.white,
                );
              },
            );
          } else {
            return const Center(child: Text("Không có dữ liệu"));
          }
        },
      ),
    );
  }
}
