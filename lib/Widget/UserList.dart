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
          'members': ['15', '21', '22', '23'], // Using IDs instead of names
        },
        {
          'name': 'GAME 2D/3D JOBS',
          'message': 'Anh: Em nhắn roi ạ - 2 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': false,
          'id': '2',
          'isGroup': true, // Mark as group chat
          'members': [
            '15',
            '24',
            '25',
            '26',
            '27'
          ], // Using IDs instead of names
        },
        {
          'name': 'Da banh ko???',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '3',
          'isGroup': true, // Mark as group chat
          'members': ['15', '28', '29', '30'], // Using IDs instead of names
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
          'name': 'Hoàng Long',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '5',
          'isGroup': false,
        },
        {
          'name': 'Minh Tuấn',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '6',
          'isGroup': false,
        },
        {
          'name': 'Thanh Hà',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '7',
          'isGroup': false,
        },
        {
          'name': 'Anh Tú',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '8',
          'isGroup': false,
        },
        {
          'name': 'Phương Linh',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '9',
          'isGroup': false,
        },
        {
          'name': 'Ngọc Ánh',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '10',
          'isGroup': false,
        },
        {
          'name': 'Thành Trung',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '11',
          'isGroup': false,
        },
        {
          'name': 'Quang Huy',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '12',
          'isGroup': false,
        },
        {
          'name': 'Hồng Nhung',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '13',
          'isGroup': false,
        },
        {
          'name': 'Văn Minh',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '14',
          'isGroup': false,
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

  Future<List<Map<String, dynamic>>> _loadNonGroupUsers() async {
    // Ensure main data is loaded first
    await _dataFuture;

    // Filter out the current user (ID 15) and group chats
    return _cachedMessages!
        .where((user) => user['isGroup'] == false && user['id'] != '15')
        .toList();
  }

  void _handleUserTap(String userId) {
    if (widget.onUserSelected != null) {
      widget.onUserSelected!(userId);
    }
  }

  void _handleCreateChat() {
    // Variables to track state
    String groupName = '';
    Map<String, bool> selectedUsers = {};
    bool isCreating = false;

    // Show dialog to create new chat
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing when clicking outside
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Create New Chat'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Chat Name',
                      hintText: 'Enter name for group chat',
                    ),
                    onChanged: (value) {
                      groupName = value;
                    },
                  ),
                  SizedBox(height: 16),
                  Text('Select Participants:'),
                  SizedBox(height: 8),
                  Container(
                    height: 300,
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _loadNonGroupUsers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Error loading users'));
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(child: Text('No users available'));
                        }

                        final users = snapshot.data!;

                        // Initialize selection map if empty
                        if (selectedUsers.isEmpty) {
                          for (var user in users) {
                            selectedUsers[user['id']] = false;
                          }
                        }

                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return CheckboxListTile(
                              title: Text(user['name']),
                              value: selectedUsers[user['id']] ?? false,
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedUsers[user['id']] = value!;
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isCreating
                    ? null
                    : () {
                        // Validate group creation
                        final selectedUserIds = selectedUsers.entries
                            .where((entry) => entry.value)
                            .map((entry) => entry.key)
                            .toList();

                        if (groupName.isEmpty || selectedUserIds.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'Please enter a group name and select at least one user')));
                          return;
                        }

                        // Set creating flag to prevent multiple clicks
                        setDialogState(() {
                          isCreating = true;
                        });

                        // Add current user ID to member list
                        final memberIds = ['15', ...selectedUserIds];

                        // Generate a new unique ID (simple approach)
                        final newId =
                            (int.parse(_cachedMessages!.last['id']) + 1)
                                .toString();

                        // Create new group chat
                        final newGroup = {
                          'name': groupName,
                          'message': 'You created this group',
                          'avatar': 'assets/logoS.jpg',
                          'isOnline': true,
                          'id': newId,
                          'isGroup': true,
                          'members': memberIds,
                        };

                        // Update the cached messages
                        setState(() {
                          _cachedMessages!.add(newGroup);
                        });

                        // Reset creating flag
                        setDialogState(() {
                          isCreating = false;
                          // Clear selections for next time
                          groupName = '';
                          for (var key in selectedUsers.keys) {
                            selectedUsers[key] = false;
                          }
                        });

                        // Notify user of success
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Group created successfully!')));
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.red.withOpacity(0.5),
                ),
                child: isCreating
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Create'),
              ),
            ],
          );
        });
      },
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
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
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
