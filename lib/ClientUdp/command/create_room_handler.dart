import 'dart:io';

import 'command_handler.dart';
import '../client_state.dart';
import '../constants.dart';
import '../handshake_manager.dart';
import '../json_helper.dart';

class CreateRoomHandler implements CommandHandler {
  @override
  void handle(String args, ClientState clientState, HandshakeManager handshakeManager) {
    if (args.trim().isEmpty) {
      print("Usage: ${Constants.CMD_CREATE_ROOM} <participant1> [participant2...]");
      stdout.write("> ");
      return;
    }

    List<String> participants = args.split(RegExp(r'\s+'));

    if (clientState.sessionKey == null) {
      print("You must be logged in to create a room. Use /login <id> <pw>");
      stdout.write("> ");
      return;
    }

    // Server-side validation is more robust, but a basic client check is helpful.
    if (participants.isEmpty) {
      print("Usage: ${Constants.CMD_CREATE_ROOM} <participant1> [participant2...]");
      stdout.write("> ");
      return;
    }

    Map<String, dynamic> data = {
      Constants.KEY_CHAT_ID: clientState.currentChatId
    };

    List<String> filteredParticipants = [];
    for (String p in participants) {
      if (p.trim().isNotEmpty) { // Avoid adding empty strings if there are multiple spaces
        filteredParticipants.add(p.trim());
      }
    }

    // Check again after trimming potential empty strings
    if (filteredParticipants.isEmpty) {
      print("Usage: ${Constants.CMD_CREATE_ROOM} <participant1> [participant2...]");
      stdout.write("> ");
      return;
    }

    data[Constants.KEY_PARTICIPANTS] = filteredParticipants;
    Map<String, dynamic> request = JsonHelper.createRequest(Constants.ACTION_CREATE_ROOM, data);
    handshakeManager.sendClientRequestWithAck(request, Constants.ACTION_CREATE_ROOM, clientState.sessionKey!);
    // No need to print "> " here
  }

  @override
  String getDescription() {
    return Constants.CMD_CREATE_ROOM_DESC;
  }
}
