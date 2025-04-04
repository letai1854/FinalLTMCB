import 'dart:io';
import 'package:intl/intl.dart';

import 'command_handler.dart';
import '../client_state.dart';
import '../constants.dart';
import '../handshake_manager.dart';
import '../json_helper.dart';

class ListMessagesHandler implements CommandHandler {
  @override
  void handle(String args, ClientState clientState, HandshakeManager handshakeManager) {
    // Fix the split method to handle the limit correctly
    List<String> parts = args.split(RegExp(r'\s+'));
    List<String> msgArgs = [];
    
    if (parts.isNotEmpty) {
      msgArgs.add(parts[0]);
      if (parts.length > 1) {
        msgArgs.add(parts.sublist(1).join(' '));
      }
    }
    
    if (msgArgs.isEmpty || msgArgs[0].trim().isEmpty) {
      print("Usage: ${Constants.CMD_LIST_MESSAGES} <room_id> [time_option]");
      stdout.write("> ");
      return;
    }

    String roomId = msgArgs[0].trim();
    // Default to "all" if time option is missing or empty
    String timeOption = (msgArgs.length > 1 && msgArgs[1].trim().isNotEmpty) 
        ? msgArgs[1].trim() 
        : Constants.TIME_OPTION_ALL;

    if (clientState.sessionKey == null) {
      print("You must be logged in to list messages. Use /login <id> <pw>");
      stdout.write("> ");
      return;
    }

    Map<String, dynamic> data = {
      Constants.KEY_CHAT_ID: clientState.currentChatId,
      Constants.KEY_ROOM_ID: roomId
    };

    // Only add from_time if a specific time option (not "all") is provided and valid
    if (timeOption.toLowerCase() != Constants.TIME_OPTION_ALL) {
      String? fromTimeIso = parseTimeOption(timeOption);
      if (fromTimeIso != null) {
        data[Constants.KEY_FROM_TIME] = fromTimeIso;
      } else {
        // parseTimeOption prints error, just return
        stdout.write("> ");
        return;
      }
    }
    // If timeOption is "all", don't add from_time

    Map<String, dynamic> request = JsonHelper.createRequest(Constants.ACTION_GET_MESSAGES, data);
    handshakeManager.sendClientRequestWithAck(request, Constants.ACTION_GET_MESSAGES, clientState.sessionKey!);
    // No need to print "> " here
  }

  /// Parses the time option string into an ISO 8601 formatted string.
  /// Handles formats like "12hours", "7days", "3weeks", "all", ISO 8601, or "yyyy-MM-dd HH:mm:ss".
  /// Returns null if the format is invalid or if the option is "all".
  /// Prints error messages for invalid formats.
  String? parseTimeOption(String timeOption) {
    timeOption = timeOption.trim().toLowerCase();
    // Use constant for comparison
    if (timeOption == Constants.TIME_OPTION_ALL) return null; // "all" means no time filter

    // Regex for "12hours", "7days", "3weeks" (plural optional)
    RegExp durationPattern = RegExp(r'^(\d+)\s*(hours?|days?|weeks?)$');
    RegExpMatch? durationMatcher = durationPattern.firstMatch(timeOption);

    DateTime now = DateTime.now();
    DateTime? fromTime;

    if (durationMatcher != null) {
      try {
        int amount = int.parse(durationMatcher.group(1)!);
        String unit = durationMatcher.group(2)!;
        if (unit.startsWith("h")) {
          fromTime = now.subtract(Duration(hours: amount));
        } else if (unit.startsWith("d")) {
          fromTime = now.subtract(Duration(days: amount));
        } else if (unit.startsWith("w")) {
          fromTime = now.subtract(Duration(days: amount * 7)); 
        }
      } catch (e) {
        print("Invalid number in time option: $timeOption");
        return null;
      }
    } else {
      // Try parsing as ISO 8601 or yyyy-MM-dd HH:mm:ss
      try {
        // Attempt ISO 8601 first (more standard)
        fromTime = DateTime.parse(timeOption);
      } catch (e1) {
        try {
          // Attempt specific format
          DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
          fromTime = formatter.parse(timeOption);
        } catch (e2) {
          print("Invalid time format. Use e.g., '12${Constants.TIME_OPTION_HOURS}', '7${Constants.TIME_OPTION_DAYS}', '3${Constants.TIME_OPTION_WEEKS}', '${Constants.TIME_OPTION_ALL}', ISO format, or 'yyyy-MM-dd HH:mm:ss'.");
          return null;
        }
      }
    }

    return fromTime?.toUtc().toIso8601String();
  }

  @override
  String getDescription() {
    return Constants.CMD_LIST_MESSAGES_DESC;
  }
}
