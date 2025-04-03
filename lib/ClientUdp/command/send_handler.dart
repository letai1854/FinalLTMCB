import 'dart:io';

import 'command_handler.dart';
import '../client_state.dart';
import '../constants.dart';
import '../handshake_manager.dart';
import '../json_helper.dart';

class SendHandler implements CommandHandler {
  @override
  void handle(String args, ClientState clientState, HandshakeManager handshakeManager) {
    List<String> parts = args.split(RegExp(r'\s+'));
    List<String> sendArgs = [];
    
    if (parts.isNotEmpty) {
      sendArgs.add(parts[0]);
      if (parts.length > 1) {
        sendArgs.add(parts.sublist(1).join(' '));
      }
    }
    
    if (sendArgs.length != 2) {
      print("Usage: ${Constants.CMD_SEND} <room_id> <message>");
      stdout.write("> ");
      return;
    }

    String roomId = sendArgs[0];
    String content = sendArgs[1];

    if (clientState.sessionKey == null) {
      print("You must be logged in to send messages. Use /login <id> <pw>");
      stdout.write("> ");
      return;
    }

    // Basic validation, server should do more thorough checks
    if (roomId.trim().isEmpty || content.isEmpty) {
      print("Usage: ${Constants.CMD_SEND} <room_id> <message>");
      stdout.write("> ");
      return;
    }

    Map<String, dynamic> data = {
      Constants.KEY_CHAT_ID: clientState.currentChatId,
      Constants.KEY_ROOM_ID: roomId.trim(),
      Constants.KEY_CONTENT: content
    };
    
    Map<String, dynamic> request = JsonHelper.createRequest(Constants.ACTION_SEND_MESSAGE, data);
    handshakeManager.sendClientRequestWithAck(request, Constants.ACTION_SEND_MESSAGE, clientState.sessionKey!);
    // No need to print "> " here
  }

  @override
  String getDescription() {
    return Constants.CMD_SEND_DESC;
  }
}
