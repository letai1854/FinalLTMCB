import 'dart:io';
import 'dart:developer' as logger;
import 'dart:convert';

import '../client_state.dart';
import '../constants.dart';
import '../handshake_manager.dart';
import '../json_helper.dart';
import 'command_handler.dart';

class LoginHandler implements CommandHandler {
  @override
  String getDescription() {
    return "/login <username> <password> - Log in to the server";
  }

  @override
  void handle(String args, ClientState clientState, HandshakeManager handshakeManager) {
    logger.log('LoginHandler processing login command with args: $args');
    
    List<String> argParts = args.split(RegExp(r'\s+'));
    
    if (argParts.length < 2) {
      logger.log('Login command missing required arguments');
      print("Usage: /login <username> <password>");
      return;
    }
    
    String username = argParts[0];
    String password = argParts[1];
    
    logger.log('Processing login for user: $username with password: $password');
    
    // Create login request data
    Map<String, dynamic> data = {
      Constants.KEY_CHAT_ID: username,
      Constants.KEY_PASSWORD: password
    };
    
    // Create login request
    Map<String, dynamic> loginRequest = JsonHelper.createRequest(Constants.ACTION_LOGIN, data);
    
    // Log the exact request being sent
    logger.log('Login request prepared: ${json.encode(loginRequest)}');
    
    // Send the login request with handshake
    String encryptionKey = Constants.FIXED_LOGIN_KEY_STRING; // Login always uses the fixed key
    logger.log('Sending login request to server for user: $username with key: "$encryptionKey" (length: ${encryptionKey.length})');
    
    // Add result handling to show login failures more clearly
    handshakeManager.sendClientRequestWithAck(loginRequest, Constants.ACTION_LOGIN, encryptionKey).then((result) {
      if (result != null && result.containsKey('status')) {
        if (result['status'] != Constants.STATUS_SUCCESS) {
          logger.log('Login failed: ${result['message']}');
          print('\nLogin failed: ${result['message']}');
        }
      }
    }).catchError((e) {
      logger.log('Error during login: $e');
    });
    
    logger.log('Login request sent, waiting for server response...');
  }
}
