import 'dart:math';
import 'package:finalltmcb/ClientUdp/client_state.dart';
import 'package:finalltmcb/ClientUdp/udpmain.dart';
import 'package:finalltmcb/Model/GroupModel.dart';
import 'package:finalltmcb/Widget/UserList.dart';
import 'package:finalltmcb/ClientUdp/json_helper.dart';  // Thêm import này
import 'package:finalltmcb/ClientUdp/constants.dart';    // Thêm import này

class GroupController {
  // Current user ID (should be obtained from a user service in a real app)
  static GroupController? _instance;
  String currentUserId = ''; // Match with UserList.dart's currentUserId
  UdpChatClient? _udpClient;
  static GroupController get instance {
    _instance ??= GroupController._internal();
    return _instance!;
  }

  GroupController._internal();

  // Getter for the UDP client
  UdpChatClient? get client => _udpClient;
  ClientState? get clientState => _udpClient?.clientState;
  // Create a new group with a name and members, then add it to the cache
  static GroupModel createGroup({
    required String name,
    required List<String> memberIds,
  }) {
    // Ensure current user is included in the group
    // if (!memberIds.contains(currentUserId)) {
    //   memberIds.insert(0, currentUserId);
    // }

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
    try {
      _udpClient = client;

      // Safe null checks
      final state = client.clientState;
      final chatId = state.currentChatId;

      if (state != null && chatId != null) {
        currentUserId = chatId;
      } else {
        currentUserId = '';
      }
    } catch (e) {
      currentUserId = '';
      rethrow;
    }
  }

  Future<void> createGroupChat(String groupName, List<String> memberIds, String idcurrent) async {
    if (_udpClient == null) {
      throw Exception('UDP Client is not initialized. Please try again later.');
    }
    if (groupName.isEmpty || memberIds.isEmpty) {
      throw Exception('Group name or member IDs cannot be empty');
    }

    // Remove current user and get other members
    final List<String> otherMembers = memberIds
        .where((id) => id != idcurrent)
        .toList();

    if (otherMembers.isEmpty) {
      throw Exception('Must have at least one other valid member');
    }

    // Chuẩn bị dữ liệu cho request
    Map<String, dynamic> data = {
      Constants.KEY_CHAT_ID: clientState!.currentChatId,
      Constants.KEY_ROOM_NAME: groupName,
      Constants.KEY_PARTICIPANTS: otherMembers
    };

    // Tạo request - Sửa lại để sử dụng JsonHelper trực tiếp
    Map<String, dynamic> request = JsonHelper.createRequest(
      Constants.ACTION_CREATE_ROOM, 
      data
    );
    
    print("Creating room '$groupName' with participants: ${otherMembers.join(", ")}");
    
    // Gửi request trực tiếp, không sử dụng commandProcessor
    _udpClient!.handshakeManager.sendClientRequestWithAck(
      request, 
      Constants.ACTION_CREATE_ROOM, 
      clientState!.sessionKey!
    );
  }
}
