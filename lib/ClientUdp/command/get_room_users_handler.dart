import '../client_state.dart';
import '../constants.dart';
import '../handshake_manager.dart';
import '../json_helper.dart';
import 'command_handler.dart';

class GetRoomUsersHandler implements CommandHandler {
  @override
  void handle(
      String args, ClientState clientState, HandshakeManager handshakeManager) {
    String roomId = args.trim();

    if (clientState.sessionKey == null) {
      print("You must be logged in to get room users. Use /login <id> <pw>");
      // stdout.write("> ");
      return;
    }

    if (roomId.isEmpty) {
      print("Room ID cannot be empty.");
      // stdout.write("> ");
      return;
    }

    Map<String, dynamic> data = {
      Constants.KEY_CHAT_ID: clientState.currentChatId,
      Constants.KEY_ROOM_ID: roomId
    };

    Map<String, dynamic> request =
        JsonHelper.createRequest(Constants.ACTION_GET_ROOM_USERS, data);
    handshakeManager.sendClientRequestWithAck(
        request, Constants.ACTION_GET_ROOM_USERS, clientState.sessionKey!);
  }

  @override
  String getDescription() => Constants.CMD_GET_ROOM_USERS_DESC;
}
