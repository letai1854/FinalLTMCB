import '../client_state.dart';
import '../constants.dart';
import '../handshake_manager.dart';
import '../json_helper.dart';
import 'command_handler.dart';

class GetUsersHandler implements CommandHandler {
  @override
  void handle(
      String args, ClientState clientState, HandshakeManager handshakeManager) {
    if (args.trim().isNotEmpty) {
      print("Usage: ${Constants.CMD_GET_USERS} (no arguments required)");
      // stdout.write("> ");
      return;
    }

    if (clientState.sessionKey == null) {
      print("You must log in first using ${Constants.CMD_LOGIN}.");
      // stdout.write("> ");
      return;
    }

    Map<String, dynamic> data = {
      Constants.KEY_CHAT_ID: clientState.currentChatId
    };

    Map<String, dynamic> request =
        JsonHelper.createRequest(Constants.ACTION_GET_USERS, data);
    handshakeManager.sendClientRequestWithAck(
        request, Constants.ACTION_GET_USERS, clientState.sessionKey!);
  }

  @override
  String getDescription() => Constants.CMD_GET_USERS_DESC;
}
