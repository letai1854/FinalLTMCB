import 'dart:io';

import 'command_handler.dart';
import '../client_state.dart';
import '../constants.dart';
import '../handshake_manager.dart';

class ExitHandler implements CommandHandler {
  @override
  void handle(String args, ClientState clientState, HandshakeManager handshakeManager) {
    print("Exiting...");
    clientState.running = false;
  }

  @override
  String getDescription() {
    return Constants.CMD_EXIT_DESC;
  }
}
