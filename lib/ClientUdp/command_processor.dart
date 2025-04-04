import 'dart:io';
import 'dart:developer' as logger;  // Add this import for logging

import 'client_state.dart';
import 'constants.dart';
import 'handshake_manager.dart';
import 'json_helper.dart'; // Add this import
import 'command/command_handler.dart';
import 'command/create_room_handler.dart';
import 'command/exit_handler.dart';
import 'command/help_handler.dart';
import 'command/list_messages_handler.dart';
import 'command/list_rooms_handler.dart';
import 'command/login_handler.dart';
import 'command/send_handler.dart';

class CommandProcessor {
  final ClientState clientState;
  final HandshakeManager handshakeManager;
  final Map<String, CommandHandler> commandHandlers = {};

  CommandProcessor(this.clientState, this.handshakeManager) {
    // Register all command handlers
    registerCommandHandler(Constants.CMD_LOGIN, LoginHandler());
    registerCommandHandler(Constants.CMD_CREATE_ROOM, CreateRoomHandler());
    registerCommandHandler(Constants.CMD_SEND, SendHandler());
    registerCommandHandler(Constants.CMD_LIST_ROOMS, ListRoomsHandler());
    registerCommandHandler(Constants.CMD_LIST_MESSAGES, ListMessagesHandler());
    registerCommandHandler(Constants.CMD_HELP, HelpHandler(this));
    registerCommandHandler(Constants.CMD_EXIT, ExitHandler());
  }
  
  void registerCommandHandler(String command, CommandHandler handler) {
    commandHandlers[command.toLowerCase()] = handler;
  }

  Future<void> processCommand(String line) async {
    logger.log('Processing command: $line');
    
    String trimmedLine = line.trim();
    if (trimmedLine.isEmpty) {
      stdout.write("> ");
      return;
    }

    if (!trimmedLine.startsWith("/")) {
      logger.log('Command does not start with "/": $trimmedLine');
      print("Invalid command. Type /help for available commands.");
      stdout.write("> ");
      return;
    }
    
    // Extract command and arguments
    List<String> allParts = trimmedLine.split(RegExp(r'\s+'));
    List<String> parts = [];
    
    if (allParts.isNotEmpty) {
      parts.add(allParts[0]);
      if (allParts.length > 1) {
        parts.add(allParts.sublist(1).join(' '));
      }
    }
    
    String command = parts[0].substring(1).toLowerCase(); // Remove the '/'
    String args = parts.length > 1 ? parts[1] : "";

    logger.log('Command: $command, Args: $args');
    if(command == "login") {
      CommandHandler? handler = commandHandlers[Constants.CMD_LOGIN.toLowerCase()];
      if (handler != null) {
        logger.log('Found registered handler for command: $command');
        handler.handle(args, clientState, handshakeManager);
      } else {
        logger.log('No registered handler found for command: $command');
        print("Invalid command. Type /help for available commands.");
        stdout.write("> ");
      }
    }
    
    // if (handler != null) {
    //   logger.log('Found registered handler for command: $command');
    //   handler.handle(line, clientState, handshakeManager);
    // } else {
    //   logger.log('No registered handler found for command: $command');
    //   // Check if it's the login command
    //   if (command == "login") {
    //     // Try to use the registered login handler if available
    //     CommandHandler? loginHandler = commandHandlers[Constants.CMD_LOGIN.toLowerCase()];
    //     if (loginHandler != null) {
    //       logger.log('Using registered login handler');
    //       loginHandler.handle(args, clientState, handshakeManager);
    //     } else {
    //       // Fallback to parsing login arguments manually if no handler found
    //       List<String> argParts = args.split(" ");
    //       if (argParts.length < 2) {
    //         logger.log('Login command missing required arguments');
    //         print("Usage: /login <username> <password>");
    //       } else {
    //         String username = argParts[0];
    //         String password = argParts[1];
    //         logger.log('Processing login using fallback method for user: $username');
    //         // Use handshakeManager directly since no handler is available
    //         Map<String, dynamic> data = {
    //           Constants.KEY_CHAT_ID: username,
    //           Constants.KEY_PASSWORD: password
    //         };
    //         Map<String, dynamic> loginRequest = JsonHelper.createRequest(Constants.ACTION_LOGIN, data);
    //         String encryptionKey = Constants.FIXED_LOGIN_KEY_STRING;
    //         logger.log('Sending login request to server for user: $username');
    //         handshakeManager.sendClientRequestWithAck(loginRequest, Constants.ACTION_LOGIN, encryptionKey);
    //       }
    //     }
    //   } else {
    //     print("Invalid command. Type /help for available commands.");
    //     stdout.write("> ");
    //   }
    // }
  }

  // This method is no longer needed since we're using the proper handler
  // Keeping it as a fallback but it won't be called in normal operation
  void processLogin(String username, String password) {
    logger.log('WARNING: Using deprecated processLogin method for user: $username');
    // Create login request data
    Map<String, dynamic> data = {
      Constants.KEY_CHAT_ID: username,
      Constants.KEY_PASSWORD: password
    };
    
    // Create login request
    Map<String, dynamic> loginRequest = JsonHelper.createRequest(Constants.ACTION_LOGIN, data);
    
    // Send the login request with handshake
    String encryptionKey = Constants.FIXED_LOGIN_KEY_STRING; // Login always uses the fixed key
    logger.log('Sending login request to server for user: $username');
    handshakeManager.sendClientRequestWithAck(loginRequest, Constants.ACTION_LOGIN, encryptionKey);
  }

  void showHelp() {
    print("\nAvailable commands:");
    commandHandlers.values.forEach((handler) {
      print("  ${handler.getDescription()}");
    });
    print("    Time options: e.g., '12${Constants.TIME_OPTION_HOURS}', '7${Constants.TIME_OPTION_DAYS}', '3${Constants.TIME_OPTION_WEEKS}', '${Constants.TIME_OPTION_ALL}', ISO format, or 'yyyy-MM-dd HH:mm:ss'");
    stdout.write("> ");
  }
  
  // Get command handlers - might be used by HelpHandler
  Map<String, CommandHandler> getCommandHandlers() {
    return commandHandlers;
  }
}
