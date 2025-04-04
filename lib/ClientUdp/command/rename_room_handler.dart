import 'dart:io';
import '../client_state.dart';
import '../constants.dart';
import '../handshake_manager.dart';
import '../json_helper.dart';
import 'command_handler.dart';

class RenameRoomHandler implements CommandHandler {
  @override
  void handle(
      String args, ClientState clientState, HandshakeManager handshakeManager) {
    // Fix: Use split() first then limit the results
    List<String> parts = args.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      print("Usage: ${Constants.CMD_RENAME_ROOM} <room_id> <new_room_name>");
      stdout.write("> ");
      return;
    }

    String roomId = parts[0];
    // Join remaining parts for room name in case it contains spaces
    String newRoomName = parts.sublist(1).join(' ');

    if (clientState.sessionKey == null) {
      print("You must be logged in to rename a room. Use /login <id> <pw>");
      stdout.write("> ");
      return;
    }

    if (roomId.isEmpty || newRoomName.isEmpty) {
      print("Room ID and new room name cannot be empty.");
      stdout.write("> ");
      return;
    }

    Map<String, dynamic> data = {
      Constants.KEY_CHAT_ID: clientState.currentChatId,
      Constants.KEY_ROOM_ID: roomId,
      Constants.KEY_ROOM_NAME: newRoomName
    };

    Map<String, dynamic> request =
        JsonHelper.createRequest(Constants.ACTION_RENAME_ROOM, data);
    handshakeManager.sendClientRequestWithAck(
        request, Constants.ACTION_RENAME_ROOM, clientState.sessionKey!);
  }

  @override
  String getDescription() => Constants.CMD_RENAME_ROOM_DESC;
}
