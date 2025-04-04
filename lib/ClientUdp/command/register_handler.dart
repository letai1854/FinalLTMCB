import '../client_state.dart';
import '../constants.dart';
import '../handshake_manager.dart';
import '../json_helper.dart';
import 'command_handler.dart';

class RegisterHandler implements CommandHandler {
  @override
  void handle(
      String args, ClientState clientState, HandshakeManager handshakeManager) {
    List<String> parts = args.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      print("Usage: ${Constants.CMD_REGISTER} <chatid> <password>");
      return;
    }

    String chatId = parts[0];
    String password = parts[1];

    if (clientState.sessionKey != null) {
      print(
          "You are already logged in as ${clientState.currentChatId}. Please log out before registering a new account.");
      return;
    }

    Map<String, dynamic> data = {
      Constants.KEY_CHAT_ID: chatId,
      Constants.KEY_PASSWORD: password
    };

    Map<String, dynamic> request =
        JsonHelper.createRequest(Constants.ACTION_REGISTER, data);
    handshakeManager.sendClientRequestWithAck(
        request, Constants.ACTION_REGISTER, Constants.FIXED_LOGIN_KEY_STRING);
  }

  @override
  String getDescription() => Constants.CMD_REGISTER_DESC;
}
