import 'dart:math'; // For generating random IDs
import 'package:finalltmcb/Model/User_model.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finalltmcb/Controllers/GroupController.dart';
import 'package:finalltmcb/ClientUdp/client_state.dart';
import 'dart:isolate';
import 'dart:async';
import 'package:finalltmcb/Service/MessageNotifier.dart'; // Add this import

class MessageList extends StatefulWidget {
  final Function(String)? onUserSelected;
  final String? selectedUserId;
  final bool isDesktopOrTablet; // Add parameter to identify view type
  // Optional GroupController that will use global instance if not provided
  final GroupController groupController;

  // Constructor takes the instance from main.dart that already has UDP client
  const MessageList({
    Key? key,
    this.onUserSelected,
    this.selectedUserId,
    this.isDesktopOrTablet = false,
    required this.groupController,
  }) : super(key: key);

  @override
  State<MessageList> createState() => _MessageListState();

  // --- Make cache public and static on the Widget class ---
  static List<Map<String, dynamic>>? cachedMessages;
  // Keep loading state and future static but potentially private to the class scope
  static bool _isLoading = false;
  static Future<List<Map<String, dynamic>>>? _dataFuture;
  // Add new static field to track unread messages
  static Set<String> unreadMessages = {};
}

class _MessageListState extends State<MessageList> {
  String get currentUserId =>
      widget.groupController.client?.clientState.currentChatId ?? '';

  @override
  void initState() {
    super.initState();
    // Initialize data from clientState
    final clientState = widget.groupController.client?.clientState;
    if (clientState != null) {
      MessageList.cachedMessages = clientState.cachedMessages;

      // Add message listener
      MessageNotifier.messageNotifier.addListener(_handleNewMessage);
      MessageNotifier.messageNotifierRoom.addListener(_handleNewRoom);
      // Thêm listener cho danh sách người dùng
      MessageNotifier.messageNotifierListUser.addListener(_handleUserListUpdate);

      if (widget.isDesktopOrTablet && clientState.cachedMessages.isNotEmpty) {
        _autoSelectFirstUser();
      }
    }
  }

  // Thêm phương thức xử lý cập nhật danh sách người dùng
  void _handleUserListUpdate() {
    if (!mounted) return;

    final userList = MessageNotifier.messageNotifierListUser.value;
    if (userList.isEmpty) return;

    setState(() {
      // Chuyển đổi danh sách người dùng từ server thành danh sách User trong ứng dụng
      final convertedUsers = _convertToUsers(userList, currentUserId);

      // Cập nhật danh sách người dùng trong ClientState
      if (widget.groupController.clientState != null) {
        widget.groupController.clientState!.convertedUsers = convertedUsers;
      }

      // Cập nhật danh sách chat dựa trên người dùng mới
    });
  }

  // Chuyển đổi danh sách ID người dùng thành danh sách đối tượng User
  List<User> _convertToUsers(List<String> userIds, String currentUserId) {
    return userIds
        .where((userId) => userId != currentUserId) // Loại bỏ ID người dùng hiện tại
        .map((userId) => User(
              chatId: userId,
              createdAt: DateTime.now(),
            ))
        .toList();
  }

  void _handleNewRoom() {
    final roomData = MessageNotifier.messageNotifierRoom.value;
    if (roomData != null && mounted) {
      setState(() {
        final roomId = roomData['room_id'];
        final roomName = roomData['room_name'];
        final List<String> members = roomData['participants'];

        print("Received new room notification - ID: $roomId, Name: $roomName");
        
        // Kiểm tra xem phòng đã tồn tại chưa
        int existingIndex =
            MessageList.cachedMessages?.indexWhere((room) => room['id'] == roomId) ?? -1;

        if (existingIndex == -1) {
          // Thêm phòng mới vào danh sách nếu chưa tồn tại
          MessageList.cachedMessages?.insert(0, {
            'id': roomId,
            'name': roomName,
            'avatar': "assets/logoS.jpg",
            'isOnline': true,
            'message': 'Phòng chat mới được tạo',
            'isGroup': true,
            'members': members, // Sử dụng List<String> thay vì Set<String>
          });

          // Initialize message container for the new room
          if (widget.groupController.clientState != null) {
            widget.groupController.clientState!.allMessagesConverted[roomId] = [];
            print("Initialized message container for new room: $roomId");
          }

          print("Đã thêm phòng chat mới: $roomName (ID: $roomId)");
        } else {
          // Cập nhật thông tin phòng nếu đã tồn tại
          MessageList.cachedMessages![existingIndex]['name'] = roomName;
          MessageList.cachedMessages![existingIndex]['members'] = members;
          print("Đã cập nhật thông tin phòng: $roomName (ID: $roomId)");
        }
      });
    }
  }

  // Add new method to handle messages
  void _handleNewMessage() {
    final messageData = MessageNotifier.messageNotifier.value;
    if (messageData != null && mounted && MessageList.cachedMessages != null) {
      final roomId = messageData['roomId'];
      final content = messageData['content'];
      final sender = messageData['sender_chatid'] ?? messageData['sender'] ?? messageData['name'] ?? 'Unknown';

      // Find the chat in cached messages
      final chatIndex = MessageList.cachedMessages!.indexWhere((chat) => chat['id'] == roomId);
      print("----------"+chatIndex.toString());
      if (chatIndex != -1) {
        setState(() {
          // Update message content with sender info
          MessageList.cachedMessages![chatIndex]['message'] = '$sender: $content';

          // Mark message as unread if it's not the currently selected chat
          if (roomId != widget.selectedUserId) {
            MessageList.unreadMessages.add(roomId);
          }

          // Move chat to top if not already there
          if (chatIndex > 0) {
            final chat = MessageList.cachedMessages!.removeAt(chatIndex);
            MessageList.cachedMessages!.insert(0, chat);
          }
        });
      } else {
        print("Warning: Received message for unknown room: $roomId");
      }
    }
  }

  @override
  void dispose() {
    MessageNotifier.messageNotifier.removeListener(_handleNewMessage);
    MessageNotifier.messageNotifierRoom.removeListener(_handleNewRoom);
    // Xóa listener cho danh sách người dùng
    MessageNotifier.messageNotifierListUser.removeListener(_handleUserListUpdate);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we should auto-select the first user after data is cached
    if (widget.isDesktopOrTablet &&
        MessageList.cachedMessages != null &&
        !MessageList._isLoading) {
      // Use class name
      _autoSelectFirstUser();
    }
  }

  void _autoSelectFirstUser() {
    if (widget.isDesktopOrTablet &&
        widget.selectedUserId == null &&
        widget.onUserSelected != null &&
        MessageList.cachedMessages != null &&
        MessageList.cachedMessages!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.selectedUserId == null) {
          // Get first message ID
          final firstMessageId = MessageList.cachedMessages![0]['id'];
          widget.onUserSelected!(firstMessageId);

          // Pre-load messages for first user
          final clientState = widget.groupController.clientState;
          if (clientState != null &&
              !clientState.allMessagesConverted.containsKey(firstMessageId)) {
            clientState.allMessagesConverted[firstMessageId] = [];
          }
        }
      });
    }
  }

  void _handleUserTap(String userId) {
    if (widget.onUserSelected != null) {
      // Mark messages as read when chat is selected
      MessageList.unreadMessages.remove(userId);

      // Ensure message history container exists before switching
      final clientState = widget.groupController.clientState;
      if (clientState != null &&
          !clientState.allMessagesConverted.containsKey(userId)) {
        clientState.allMessagesConverted[userId] = [];
      }
      widget.onUserSelected!(userId);

      // Trigger rebuild to update message styling
      setState(() {});
    }
  }

  Future<List<Map<String, dynamic>>> _loadData() async {
    // Return cached data if available
    if (MessageList.cachedMessages != null) {
      // Use class name
      return MessageList.cachedMessages!; // Use class name
    }

    // Prevent concurrent loading
    if (MessageList._isLoading) {
      // Use class name
      // Wait until loading completes
      while (MessageList._isLoading) {
        // Use class name
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return MessageList.cachedMessages!; // Use class name
    }

    MessageList._isLoading = true; // Use class name

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      MessageList.cachedMessages = [];

      // Auto-select first user only for desktop/tablet
      if (widget.isDesktopOrTablet && mounted) {
        _autoSelectFirstUser();
      }

      return MessageList.cachedMessages!; // Use class name
    } finally {
      MessageList._isLoading = false; // Use class name
    }
  }

  // *** Định nghĩa lại hàm _createGroupChat ***
  Future<void> _createGroupChat(
      String groupName, List<String> memberIds) async {
    final completer = Completer<void>();
    final receivePort = ReceivePort();

    // Spawn isolate for group creation
    final isolate = await Isolate.spawn((List<dynamic> args) {
      final SendPort sendPort = args[0];
      final Map<String, dynamic> data = args[1];

      try {
        sendPort.send({
          'type': 'execute',
          'groupName': data['groupName'],
          'memberIds': data['memberIds'],
        });
      } catch (e) {
        sendPort.send({'type': 'error', 'message': e.toString()});
      }
    }, [
      receivePort.sendPort,
      {'groupName': groupName, 'memberIds': memberIds}
    ]);

    // Listen for messages from isolate
    receivePort.listen((message) async {
      if (message['type'] == 'execute') {
        try {
          await widget.groupController.createGroupChat(
            message['groupName'],
            message['memberIds'],
            currentUserId, // Use the state's getter for the current user ID
          );

          // // --- START: Update cache and trigger rebuild ---
          // // Tạo group mới để thêm vào cache
          // final newGroupId =
          //     'room${(MessageList.cachedMessages?.where((m) => m['isGroup'] == true).length ?? 0) + 1}';
          // final newGroup = {
          //   'name': message['groupName'],
          //   'message': 'New group created', // Placeholder message
          //   'avatar': 'assets/logoS.jpg', // Placeholder avatar
          //   'isOnline': true, // Placeholder status
          //   'id': newGroupId, // Lưu ID để sử dụng sau
          //   'isGroup': true,
          //   'members': message['memberIds'],
          // };

          // // Ensure cache is initialized
          // MessageList.cachedMessages ??= [];
          // // Add to the beginning of the list
          // MessageList.cachedMessages!.insert(0, newGroup);

          // // Trigger UI rebuild
          // if (mounted) {
          //   setState(() {});

          //   // Tự động chọn group mới sau khi UI đã được cập nhật
          //   WidgetsBinding.instance.addPostFrameCallback((_) {
          //     if (mounted && widget.onUserSelected != null) {
          //       // Chọn group mới bằng cách gọi callback với ID của group
          //       widget.onUserSelected!(newGroupId); // Truyền String ID
          //     }
          //   });
          // }
          // --- END: Update cache and trigger rebuild ---

          completer.complete();
        } catch (e) {
          completer.completeError(e);
        }
      } else if (message['type'] == 'error') {
        completer.completeError(message['message']);
      }

      isolate.kill();
      receivePort.close(); // Close the port when done
    });

    return completer.future;
  }
  // ******************************************

  void _handleCreateChat() {
    // --- Dialog State Variables ---
    String searchQuery = '';
    final Set<String> selectedUserIds = {};
    final TextEditingController searchController = TextEditingController();
    final TextEditingController groupNameController = TextEditingController();

    // Sử dụng listUsers thay vì potentialMembers
    // final List<Map<String, dynamic>> potentialMembers = (MessageList.cachedMessages ?? [])
    //     .where((msg) => msg['isGroup'] == false && msg['id'] != currentUserId)
    //     .toList();

    // Group counter for generating room IDs
    int existingGroups = (MessageList.cachedMessages ?? [])
        .where((msg) => msg['isGroup'] == true)
        .length;
    int nextGroupNumber = existingGroups + 1;

    // Show dialog to create new chat
    showDialog(
      context: context,
      builder: (context) {
        // Use StatefulBuilder to manage dialog state locally
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Filter users based on search query
            var filteredUsers =
                (widget.groupController.client?.clientState.convertedUsers ?? [])
                    .where((user) => user.chatId
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
                      labelText: 'Group Name',
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
                      setDialogState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                  SizedBox(height: 8),
                  Text('Select Participants:'),
                  SizedBox(height: 8),
                  Container(
                    height: 200,
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: filteredUsers.isEmpty
                        ? Center(child: Text('No users found or available'))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              final userId = user.chatId;
                              // Sử dụng chatId làm tên hiển thị
                              final userName = user.chatId;
                              // Sử dụng avatar mặc định
                              final avatarPath = 'assets/logoS.jpg';

                              final bool isSelected =
                                  selectedUserIds.contains(userId);

                              return CheckboxListTile(
                                secondary: CircleAvatar(
                                  backgroundImage: AssetImage(avatarPath),
                                  radius: 18,
                                ),
                                title: Text(userName),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setDialogState(() {
                                    if (value == true) {
                                      selectedUserIds.add(userId);
                                    } else {
                                      selectedUserIds.remove(userId);
                                    }
                                  });
                                },
                                dense: true,
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
                  onPressed: selectedUserIds.isEmpty
                      ? null
                      : () async {
                          if (MessageList.cachedMessages == null) return;

                          // Generate room ID
                          final String roomId = 'room$nextGroupNumber';

                          // Get group name or generate default
                          String groupName = groupNameController.text.trim();
                          if (groupName.isEmpty) {
                            groupName = 'Group Chat $nextGroupNumber';
                          }

                          // Create array of all users (including current user)
                          final List<String> allUsers = [
                            currentUserId,
                            ...selectedUserIds
                          ];

                          try {
                            // Create group using isolate
                            await _createGroupChat(groupName,
                                allUsers); // Gọi hàm đã định nghĩa lại
                            Navigator.pop(context);
                          } catch (e) {
                            print('Error creating group: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())));
                          }
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
              MessageList.cachedMessages == null) {
            // Use class name
            return const Center(child: CircularProgressIndicator());
          } else if ((snapshot.hasData && snapshot.data != null) ||
              MessageList.cachedMessages != null) {
            // Use class name
            final messages =
                MessageList.cachedMessages ?? snapshot.data!; // Use class name
            return ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isSelected = message['id'] ==
                    widget.selectedUserId; // Sửa lại check theo ID và tên biến
                final isUnread =
                    MessageList.unreadMessages.contains(message['id']);
                return ListTile(
                  selected: isSelected,
                  selectedTileColor: Colors.red.withOpacity(0.1),
                  onTap: () => _handleUserTap(
                      message['id']), // Gọi hàm xử lý tap với String ID
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
                  subtitle: Text(
                    message['message']!,
                    style: TextStyle(
                      color: isUnread ? Colors.black87 : Colors.grey[600],
                      fontWeight:
                          isUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
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
