import 'dart:math';
import 'package:finalltmcb/ClientUdp/udpmain.dart';
import 'package:finalltmcb/Model/GroupModel.dart';
import 'package:finalltmcb/Widget/UserList.dart';

class GroupController {
  // Current user ID (should be obtained from a user service in a real app)
  static const String currentUserId = 'user1';  // Match with UserList.dart's currentUserId
  UdpChatClient? _udpClient;
  // Create a new group with a name and members, then add it to the cache
  static GroupModel createGroup({
    required String name,
    required List<String> memberIds,
  }) {
    // Ensure current user is included in the group
    if (!memberIds.contains(currentUserId)) {
      memberIds.insert(0, currentUserId);
    }

    // Generate a unique ID
    final id = _generateUniqueId();

    // Create the group model
    final group = GroupModel(
      id: id,
      name: name,
      message: 'Group created',
      isGroup: true,
      members: memberIds,
    );
    // Add to MessageList cache if available
    if (MessageList.cachedMessages != null) {
      // Insert at the beginning of the list
      MessageList.cachedMessages!.insert(0, group.toMap());
    }

    return group;
  }

  // Helper to generate a unique ID for a new group
  static String _generateUniqueId() {
    return 'group_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }
    void setUdpClient(UdpChatClient client) {
    _udpClient = client;
  }
  Future<void> createGroupChat(String groupName, List<String> memberIds) async {
    if (_udpClient == null) {
      throw Exception('UDP Client is not initialized. Please try again later.');
    }
    if (groupName.isEmpty || memberIds.isEmpty) {
      throw Exception('Group name or member IDs cannot be empty');
    }

    // Validate group name format (no spaces, special characters)
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(groupName)) {
      throw Exception('Group name can only contain letters, numbers, and underscores');
    }

    // Remove current user and get other members
    final List<String> otherMembers = memberIds.where((id) => 
      id != currentUserId && // Remove current user
      id != groupName &&     // Remove group name if it's in the list
      RegExp(r'^user\d+$').hasMatch(id) // Only allow userX format
    ).toList();
    
    if (otherMembers.isEmpty) {
      throw Exception('Must have at least one other valid member');
    }
    print('Creating group with name: $groupName and members: $otherMembers');
    // Format command: /create <room_name> <user2> [user3 ...]
    _udpClient?.commandProcessor.processCommand(
      '/create $groupName ${otherMembers.join(' ')}',
    );
  }
}
