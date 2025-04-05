import 'dart:io';
import 'dart:developer' as logger; // Add this import for logging

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
import 'command/rename_room_handler.dart';
import 'command/register_handler.dart';
import 'command/remove_user_handler.dart';
import 'command/get_room_users_handler.dart';
import 'command/get_users_handler.dart';
import 'command/add_user_handler.dart';
import 'command/delete_room_handler.dart';

class CommandProcessor {
  final ClientState clientState;
  final HandshakeManager handshakeManager;
  final Map<String, CommandHandler> commandHandlers = {};

  CommandProcessor(this.clientState, this.handshakeManager) {
    // Register commands in same order as Java version
    registerCommandHandler(Constants.CMD_REGISTER, RegisterHandler());
    registerCommandHandler(Constants.CMD_GET_USERS, GetUsersHandler());
    registerCommandHandler(Constants.CMD_LOGIN, LoginHandler());
    registerCommandHandler(Constants.CMD_CREATE_ROOM, CreateRoomHandler());
    registerCommandHandler(Constants.CMD_SEND, SendHandler());
    registerCommandHandler(Constants.CMD_LIST_ROOMS, ListRoomsHandler());
    registerCommandHandler(Constants.CMD_LIST_MESSAGES, ListMessagesHandler());
    registerCommandHandler(Constants.CMD_ADD_USER, AddUserHandler());
    registerCommandHandler(Constants.CMD_REMOVE_USER, RemoveUserHandler());
    registerCommandHandler(Constants.CMD_DELETE_ROOM, DeleteRoomHandler());
    registerCommandHandler(Constants.CMD_RENAME_ROOM, RenameRoomHandler());
    registerCommandHandler(Constants.CMD_GET_ROOM_USERS, GetRoomUsersHandler());
    registerCommandHandler(Constants.CMD_HELP, HelpHandler(this));
    registerCommandHandler(Constants.CMD_EXIT, ExitHandler());
  }

  void registerCommandHandler(String command, CommandHandler handler) {
    commandHandlers[command.toLowerCase()] = handler;
  }

  Future<void> processCommand(String line) async {
    logger.log('Processing command: $line');
    print(line);
    String trimmedLine = line.trim();
    if (trimmedLine.isEmpty) {
      stdout.write("> ");
      return;
    }

    // Split into command and args, preserving spaces in args
    int spaceIndex = trimmedLine.indexOf(' ');
    List<String> parts;
    if (spaceIndex == -1) {
      parts = [trimmedLine];
    } else {
      parts = [
        trimmedLine.substring(0, spaceIndex),
        trimmedLine.substring(spaceIndex + 1)
      ];
    }
    String command = parts[0].toLowerCase();
    String args = parts.length > 1 ? parts[1] : "";

    logger.log('Command: $command, Args: $args');
    
    CommandHandler? handler = commandHandlers[command];
    if (handler != null) {
      logger.log('Found registered handler for command: $command');
      try {
        handler.handle(args, clientState, handshakeManager);
      } catch (e) {
        logger.log('Error executing command: $e');
        print("Error executing command. Please try again.");
      }
      stdout.write("> ");
    } else {
      logger.log('No registered handler found for command: $command');
      print("Invalid command. Type /help for available commands.");
      stdout.write("> ");
    }
  }

  // This method is no longer needed since we're using the proper handler
  // Keeping it as a fallback but it won't be called in normal operation
  void processLogin(String username, String password) {
    logger.log(
        'WARNING: Using deprecated processLogin method for user: $username');
    // Create login request data
    Map<String, dynamic> data = {
      Constants.KEY_CHAT_ID: username,
      Constants.KEY_PASSWORD: password
    };

    // Create login request
    Map<String, dynamic> loginRequest =
        JsonHelper.createRequest(Constants.ACTION_LOGIN, data);

    // Send the login request with handshake
    String encryptionKey =
        Constants.FIXED_LOGIN_KEY_STRING; // Login always uses the fixed key
    logger.log('Sending login request to server for user: $username');
    handshakeManager.sendClientRequestWithAck(
        loginRequest, Constants.ACTION_LOGIN, encryptionKey);
  }

  void showHelp() {
    print("\nAvailable commands:");
    commandHandlers.values.forEach((handler) {
      print("  ${handler.getDescription()}");
    });
    print(
        "    Time options: e.g., '12${Constants.TIME_OPTION_HOURS}', '7${Constants.TIME_OPTION_DAYS}', '3${Constants.TIME_OPTION_WEEKS}', '${Constants.TIME_OPTION_ALL}', ISO format, or 'yyyy-MM-dd HH:mm:ss'");
    stdout.write("> ");
  }

  // Get command handlers - might be used by HelpHandler
  Map<String, CommandHandler> getCommandHandlers() {
    return commandHandlers;
  }
}
