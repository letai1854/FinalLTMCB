import '../client_state.dart';
import '../constants.dart';
import '../handshake_manager.dart';
import '../json_helper.dart';
import 'command_handler.dart';

class DeleteRoomHandler implements CommandHandler {
  @override
  void handle(
      String args, ClientState clientState, HandshakeManager handshakeManager) {
    String roomId = args.trim();

    if (clientState.sessionKey == null) {
      print("You must be logged in to delete a room. Use /login <id> <pw>");
      return;
    }

    if (roomId.isEmpty) {
      print("Room ID cannot be empty.");
      return;
    }

    Map<String, dynamic> data = {
      Constants.KEY_CHAT_ID: clientState.currentChatId,
      Constants.KEY_ROOM_ID: roomId
    };

    Map<String, dynamic> request =
        JsonHelper.createRequest(Constants.ACTION_DELETE_ROOM, data);
    handshakeManager.sendClientRequestWithAck(
        request, Constants.ACTION_DELETE_ROOM, clientState.sessionKey!);
  }

  @override
  String getDescription() => Constants.CMD_DELETE_ROOM_DESC;
}
