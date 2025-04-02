import 'dart:math';
import 'package:finalltmcb/Model/GroupModel.dart';
import 'package:finalltmcb/Widget/UserList.dart';

class GroupController {
  // Current user ID (should be obtained from a user service in a real app)
  static const String currentUserId = '15';

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
}
