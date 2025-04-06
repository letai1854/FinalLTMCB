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
      print("Usage: ${Constants.CMD_CREATE_ROOM} <room_name> <participant1> [participant2...]");
      stdout.write("> ");
      return;
    }

    List<String> arguments = args.split(RegExp(r'\s+'));
    
    // Make sure we have at least 2 arguments (room_name and at least one participant)
    if (arguments.length < 2) {
      print("Usage: ${Constants.CMD_CREATE_ROOM} <room_name> <participant1> [participant2...]");
      stdout.write("> ");
      return;
    }

    if (clientState.sessionKey == null) {
      print("You must be logged in to create a room. Use /login <id> <pw>");
      stdout.write("> ");
      return;
    }

    // Extract room name (first argument) and participants (remaining arguments)
    String roomName = arguments[0].trim();
    List<String> participants = arguments.sublist(1);
    
    if (roomName.isEmpty) {
      print("Room name cannot be empty");
      stdout.write("> ");
      return;
    }

    // Filter participants to remove empty entries
    List<String> filteredParticipants = [];
    for (String p in participants) {
      if (p.trim().isNotEmpty) {
        filteredParticipants.add(p.trim());
      }
    }

    // Check that we have at least one valid participant
    if (filteredParticipants.isEmpty) {
      print("You must specify at least one participant");
      stdout.write("> ");
      return;
    }

    // Create data with the required format
    Map<String, dynamic> data = {
      Constants.KEY_CHAT_ID: clientState.currentChatId,
      'room_name': roomName,
      Constants.KEY_PARTICIPANTS: filteredParticipants
    };

    Map<String, dynamic> request = JsonHelper.createRequest(
      Constants.ACTION_CREATE_ROOM, 
      data
    );
    
    handshakeManager.sendClientRequestWithAck(
      request, 
      Constants.ACTION_CREATE_ROOM, 
      clientState.sessionKey!
    );
  }

  @override
  String getDescription() {
    return Constants.CMD_CREATE_ROOM_DESC;
  }
}
