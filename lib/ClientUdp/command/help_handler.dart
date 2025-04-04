import 'command_handler.dart';
import '../client_state.dart';
import '../command_processor.dart';
import '../constants.dart';
import '../handshake_manager.dart';

class HelpHandler implements CommandHandler {
  final CommandProcessor commandProcessor;
  
  HelpHandler(this.commandProcessor);

  @override
  void handle(String args, ClientState clientState, HandshakeManager handshakeManager) {
    commandProcessor.showHelp();
  }

  @override
  String getDescription() {
    return Constants.CMD_HELP_DESC;
  }
}
