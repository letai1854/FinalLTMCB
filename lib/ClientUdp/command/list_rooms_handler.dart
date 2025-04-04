import 'dart:io';

import 'command_handler.dart';
import '../client_state.dart';
import '../constants.dart';
import '../handshake_manager.dart';
import '../json_helper.dart';

class ListRoomsHandler implements CommandHandler {
  @override
  void handle(
      String args, ClientState clientState, HandshakeManager handshakeManager) {
    // This command doesn't take arguments, but we check for login status.
    if (clientState.sessionKey == null) {
      print("You must be logged in to list rooms. Use /login <id> <pw>");
      stdout.write("> ");
      return;
    }

    Map<String, dynamic> data = {
      Constants.KEY_CHAT_ID: clientState.currentChatId
    };

    Map<String, dynamic> request =
        JsonHelper.createRequest(Constants.ACTION_GET_ROOMS, data);
    handshakeManager.sendClientRequestWithAck(
        request, Constants.ACTION_GET_ROOMS, clientState.sessionKey!);
    // No need to print "> " here
  }

  @override
  String getDescription() {
    return Constants.CMD_LIST_ROOMS_DESC;
  }
}
