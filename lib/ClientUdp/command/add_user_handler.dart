import '../client_state.dart';
import '../constants.dart';
import '../handshake_manager.dart';
import '../json_helper.dart';
import 'command_handler.dart';

class AddUserHandler implements CommandHandler {
  @override
  void handle(
      String args, ClientState clientState, HandshakeManager handshakeManager) {
    List<String> parts = args.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      print("Usage: ${Constants.CMD_ADD_USER} <room_id> <username>");
      return;
    }

    String roomId = parts[0];
    String userToAdd = parts.sublist(1).join(' ');

    if (clientState.sessionKey == null) {
      print(
          "You must be logged in to add users to a room. Use /login <id> <pw>");
      return;
    }

    if (roomId.isEmpty || userToAdd.isEmpty) {
      print("Room ID and username cannot be empty.");
      return;
    }

    Map<String, dynamic> data = {
      Constants.KEY_CHAT_ID: clientState.currentChatId,
      Constants.KEY_ROOM_ID: roomId,
      "user_to_add": userToAdd
    };

    Map<String, dynamic> request =
        JsonHelper.createRequest(Constants.ACTION_ADD_USER_TO_ROOM, data);
    handshakeManager.sendClientRequestWithAck(
        request, Constants.ACTION_ADD_USER_TO_ROOM, clientState.sessionKey!);
  }

  @override
  String getDescription() => Constants.CMD_ADD_USER_DESC;
}
