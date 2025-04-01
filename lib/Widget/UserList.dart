import 'dart:math'; // For generating random IDs
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
  @override
  State<MessageList> createState() => _MessageListState();

  // --- Make cache public and static on the Widget class ---
  static List<Map<String, dynamic>>? cachedMessages;
  // Keep loading state and future static but potentially private to the class scope
  static bool _isLoading = false;
  static Future<List<Map<String, dynamic>>>? _dataFuture;
}

class _MessageListState extends State<MessageList> {
  // Static variables are now moved to the MessageList class above

  // Current user ID (assuming '15' as per requirement)
  static const String currentUserId = '15';

  @override
  void initState() {
    super.initState();
    // Initialize the future if not already created
    if (MessageList._dataFuture == null) { // Use class name
      MessageList._dataFuture = _loadData(); // Use class name
    }

    // Listen for auto-selection only once after initial data load
    if (widget.isDesktopOrTablet && MessageList.cachedMessages != null && !MessageList._isLoading) { // Use class name
      _autoSelectFirstUser();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we should auto-select the first user after data is cached
    if (widget.isDesktopOrTablet && MessageList.cachedMessages != null && !MessageList._isLoading) { // Use class name
      _autoSelectFirstUser();
    }
  }

  void _autoSelectFirstUser() {
    // Only select first user if we're in desktop/tablet mode, have data,
    // no user is selected yet, and we have a callback
    if (widget.isDesktopOrTablet &&
        widget.selectedUserId == null &&
        widget.onUserSelected != null &&
        MessageList.cachedMessages != null && // Use class name
        MessageList.cachedMessages!.isNotEmpty) {
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.selectedUserId == null) {
          widget.onUserSelected!(MessageList.cachedMessages![0]['id']); // Use class name
        }
      });
    }
  }
//
  Future<List<Map<String, dynamic>>> _loadData() async {
    // Return cached data if available
    if (MessageList.cachedMessages != null) { // Use class name
      return MessageList.cachedMessages!; // Use class name
    }

    // Prevent concurrent loading
    if (MessageList._isLoading) { // Use class name
      // Wait until loading completes
      while (MessageList._isLoading) { // Use class name
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return MessageList.cachedMessages!; // Use class name
    }

    MessageList._isLoading = true; // Use class name

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data
      MessageList.cachedMessages = [ // Use class name
        {
          'name': 'Dory Family',
          'message': 'Tân: import java.io.*; import java.... 2 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '1',
          'isGroup': true, // Mark as group chat
          'members': [currentUserId, '101', '102', '103'], // Store IDs for groups
        },
        {
          'name': 'GAME 2D/3D JOBS',
          'message': 'Anh: Em nhắn roi ạ - 2 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': false,
          'id': '2',
          'isGroup': true, // Mark as group chat
          'members': [currentUserId, '104', '105', '106', '107'], // Store IDs for groups
        },
        {
          'name': 'Da banh ko???',
          'message': 'Nguyễn Minh Trường đã thêm G... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '3',
          'isGroup': true, // Mark as group chat
          'members': [currentUserId, '108', '109', '110'], // Store IDs for groups
        },
        {
          'name': 'Mai Anh', // This is an individual chat
          'message': 'Hẹn gặp lại bạn cuối tuần nhé! 1 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '4',
          'isGroup': false,
          'members': [], // Add empty members list
        },
        {
          'name': 'User 5', // Placeholder name
          'message': 'Placeholder message... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '5',
          'isGroup': false, // Add isGroup
          'members': [], // Add empty members list
        },
        {
          'name': 'User 6', // Placeholder name
          'message': 'Placeholder message... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '6',
          'isGroup': false, // Add isGroup
          'members': [], // Add empty members list
        },
        {
          'name': 'User 7', // Placeholder name
          'message': 'Placeholder message... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '7',
          'isGroup': false, // Add isGroup
          'members': [], // Add empty members list
        },
        {
          'name': 'User 8', // Placeholder name
          'message': 'Placeholder message... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '8',
          'isGroup': false, // Add isGroup
          'members': [], // Add empty members list
        },
        {
          'name': 'User 9', // Placeholder name
          'message': 'Placeholder message... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '9',
          'isGroup': false, // Add isGroup
          'members': [], // Add empty members list
        },
        {
          'name': 'User 10', // Placeholder name
          'message': 'Placeholder message... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '10',
          'isGroup': false, // Add isGroup
          'members': [], // Add empty members list
        },
        {
          'name': 'User 11', // Placeholder name
          'message': 'Placeholder message... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '11',
          'isGroup': false, // Add isGroup
          'members': [], // Add empty members list
        },
        {
          'name': 'User 12', // Placeholder name
          'message': 'Placeholder message... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '12',
          'isGroup': false, // Add isGroup
          'members': [], // Add empty members list
        },
        {
          'name': 'User 13', // Placeholder name
          'message': 'Placeholder message... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '13',
          'isGroup': false, // Add isGroup
          'members': [], // Add empty members list
        },
        {
          'name': 'User 14', // Placeholder name
          'message': 'Placeholder message... 6 giờ',
          'avatar': 'assets/logoS.jpg',
          'isOnline': true,
          'id': '14',
          'isGroup': false, // Add isGroup
          'members': [], // Add empty members list
        },
      ];

      // Auto-select first user only for desktop/tablet
      if (widget.isDesktopOrTablet && mounted) {
        _autoSelectFirstUser();
      }

      return MessageList.cachedMessages!; // Use class name
    } finally {
      MessageList._isLoading = false; // Use class name
    }
  }

  void _handleUserTap(String userId) {
    if (widget.onUserSelected != null) {
      widget.onUserSelected!(userId);
    }
  }

  void _handleCreateChat() {
    // --- Dialog State Variables ---
    String searchQuery = '';
    final Set<String> selectedUserIds = {};
    final TextEditingController searchController = TextEditingController();
    final TextEditingController groupNameController = TextEditingController();
    // Initial list calculation (potential members are individual chats excluding self)
    final List<Map<String, dynamic>> potentialMembers = (MessageList.cachedMessages ?? []) // Use class name
        .where((msg) => msg['isGroup'] == false && msg['id'] != currentUserId)
        .toList();

    // Show dialog to create new chat
    showDialog(
      context: context,
      builder: (context) {
        // Use StatefulBuilder to manage dialog state locally
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Filter the base list based on the current searchQuery *inside* the builder
            final List<Map<String, dynamic>> filteredMembers = potentialMembers
                .where((msg) => (msg['name'] as String? ?? '')
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()))
                .toList();

            return AlertDialog(
              title: Text('Create New Group Chat'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: groupNameController,
                    decoration: InputDecoration(
                      labelText: 'Group Name (Optional)',
                      hintText: 'Enter name for group chat',
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Users',
                      hintText: 'Type to search...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      // Use setDialogState to update the search query and trigger rebuild
                      setDialogState(() {
                        searchQuery = value;
                        // No need to explicitly re-filter here,
                        // potentialMembers is recalculated at the start of the builder
                      });
                    },
                  ),
                  SizedBox(height: 8),
                  Text('Select Participants:'),
                  SizedBox(height: 8),
                  Container(
                    height: 200, // Constrained height
                    width: double.maxFinite, // Take available width
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: filteredMembers.isEmpty // Use filtered list
                        ? Center(child: Text('No users found or available'))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredMembers.length, // Use filtered list
                            itemBuilder: (context, index) {
                              final user = filteredMembers[index]; // Use filtered list
                              final userId = user['id'] as String;
                              final userName = user['name'] as String? ?? 'Unknown User';
                              final avatarPath = user['avatar'] as String? ?? 'assets/logoS.jpg'; // Default avatar if missing

                              // Check if the current user ID is in the selection set
                              final bool isSelected = selectedUserIds.contains(userId);

                              return CheckboxListTile(
                                secondary: CircleAvatar( // Add avatar here
                                  backgroundImage: AssetImage(avatarPath),
                                  radius: 18, // Smaller avatar
                                ),
                                title: Text(userName),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  // Use setDialogState to update the selection
                                  setDialogState(() {
                                    if (value == true) {
                                      selectedUserIds.add(userId);
                                    } else {
                                      selectedUserIds.remove(userId);
                                    }
                                  });
                                },
                                dense: true, // Makes the list item smaller
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
                  onPressed: selectedUserIds.isEmpty // Disable if no users selected
                      ? null
                      : () {
                          // --- Create Group Logic ---
                          if (MessageList.cachedMessages == null) return; // Use class name

                          // 1. Combine selected IDs with current user ID
                          final List<String> memberIds = [currentUserId, ...selectedUserIds];

                          // 2. Get member names from _cachedMessages for default naming
                          // Need a helper function or map for quick lookup
                          Map<String, String> userIdToNameMap = {
                            for (var msg in MessageList.cachedMessages!) msg['id']: msg['name'] // Use class name
                          };
                          // Add current user if not already in cache (should be)
                          userIdToNameMap.putIfAbsent(currentUserId, () => 'You');

                          final List<String> memberNames = memberIds
                              .map((id) => userIdToNameMap[id] ?? 'Unknown')
                              .toList();

                          // 3. Generate Group Name if not provided
                          String groupName = groupNameController.text.trim();
                          if (groupName.isEmpty) {
                             // Create a default name like "You, Mai Anh, User 5"
                             groupName = memberNames.take(3).join(', ');
                             if (memberNames.length > 3) {
                               groupName += '...';
                             }
                          }

                          // 4. Generate unique ID
                          final String newGroupId =
                              'group_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

                          // 5. Create new group map
                          final newGroup = {
                            'id': newGroupId,
                            'name': groupName,
                            'message': 'Group created by You', // Initial message
                            'avatar': 'assets/logoS.jpg', // Default group avatar
                            'isOnline': false, // Groups aren't 'online'
                            'isGroup': true,
                            'members': memberIds, // STORE THE IDs
                          };

                          // 6. Close dialog FIRST
                          Navigator.pop(context);

                          // 7. Add to cache and update state OUTSIDE the dialog's builder
                          // Use the main widget's setState
                          setState(() {
                            MessageList.cachedMessages!.insert(0, newGroup); // Use class name
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.red.withOpacity(0.5),
                  ),
                  child: Text('Create'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Dispose controllers after the dialog is closed
      searchController.dispose();
      groupNameController.dispose();
    });
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
        future: MessageList._dataFuture, // Use class name
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (snapshot.connectionState == ConnectionState.waiting &&
              MessageList.cachedMessages == null) { // Use class name
            return const Center(child: CircularProgressIndicator());
          } else if ((snapshot.hasData && snapshot.data != null) ||
              MessageList.cachedMessages != null) { // Use class name
            final messages = MessageList.cachedMessages ?? snapshot.data!; // Use class name
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
                            // Display member count for groups based on the 'members' list (which now holds IDs)
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
