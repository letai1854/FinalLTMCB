import 'dart:io';
import 'dart:convert'; // Add this import for JSON decoding
import 'dart:developer' as logger;
import 'package:finalltmcb/Service/MessageNotifier.dart';
import 'package:intl/intl.dart';

import 'client_state.dart';
import 'constants.dart';

class MessageProcessor {
  final ClientState clientState;

  MessageProcessor(this.clientState);

  /**
   * Processes the JSON content of a server message after it has been confirmed
   * by the handshake protocol (S->C flow).
   */
  void processServerAction(String jsonString) {
    try {
      Map<String, dynamic> responseJson = json.decode(jsonString);
      if (!responseJson.containsKey(Constants.KEY_ACTION)) {
        logger.log(
            'Confirmed server action JSON missing \'action\' field: $jsonString');
        return;
      }

      String action = responseJson[Constants.KEY_ACTION];
      String? status = responseJson[Constants
          .KEY_STATUS]; // Status might not always be present in S->C initial actions
      String? message = responseJson[Constants.KEY_MESSAGE];
      Map<String, dynamic>? data = responseJson[Constants.KEY_DATA];

      logger.log('Processing confirmed server action: $action');

      // Note: Login success is now handled directly in HandshakeManager's ACK handler
      // to update sessionKey immediately. We don't process ACTION_LOGIN_SUCCESS here.

      switch (action) {
        case Constants.ACTION_ROOM_CREATED:
          if (Constants.STATUS_SUCCESS == status &&
              data != null &&
              data.containsKey(Constants.KEY_ROOM_ID)) {
            String roomId = data[Constants.KEY_ROOM_ID];
            print("\nRoom created successfully! ID: $roomId");
            print(
                "You can now send messages using: /send $roomId <your_message>");
          } else {
            print("\nRoom creation failed: ${message ?? "Unknown reason"}");
          }
          break;
        case Constants.ACTION_RECIEVE_ROOM:
          if(data!=null){
            print(data);
            String roomId = data[Constants.KEY_ROOM_ID];
            String roomName = data[Constants.KEY_ROOM_NAME];
            
            // Lấy danh sách người tham gia và giữ nguyên dạng List<String>
            List<dynamic> participantsList = data[Constants.KEY_PARTICIPANTS];
            List<String> participants = participantsList.map((item) => item.toString()).toList();
            
            print(roomId);
            print(roomName);
            print(participants);
            
            MessageNotifier.updateDataRoom({
              'room_id': roomId,
              'room_name': roomName,
              'participants': participants, // Giữ dạng List<String>
            });
          }
          break;
          print(Constants.ACTION_RECIEVE_LISTUSER);
          case Constants.ACTION_RECIEVE_LISTUSER:
          if(data!=null){
            print(data);
            List<dynamic> participantsList = data[Constants.KEY_PARTICIPANTS];
            List<String> participants = participantsList.map((item) => item.toString()).toList();
            print(participants);
            MessageNotifier.updateListUser(participants);
          }
          break;

          print(Constants.ACTION_RECIEVE_LISTUSER);
          print("-----------");
        case Constants.ACTION_RECEIVE_MESSAGE:
          // RECEIVE_MESSAGE comes directly from server (S->C), status might not be relevant here, focus on data
          if (data != null &&data.containsKey(Constants.KEY_ROOM_ID) &&data.containsKey(Constants.KEY_SENDER_CHAT_ID) &&data.containsKey(Constants.KEY_CONTENT) &&data.containsKey(Constants.KEY_TIMESTAMP)) {
            String roomId = data[Constants.KEY_ROOM_ID];
            String sender = data[Constants.KEY_SENDER_CHAT_ID];
            String content = data[Constants.KEY_CONTENT];
            String timestampStr = data[Constants.KEY_TIMESTAMP];
            String formattedTime = formatTimestamp(timestampStr, "HH:mm:ss");
            print("\n[$roomId] $sender @ $formattedTime: $content");
            MessageNotifier.updateMessage({
              'roomId': roomId,
              'sender': sender,
              'content': content,
              'timestamp': timestampStr,
              'formattedTime': formattedTime
            });
          } else {
            logger.log('Received invalid RECEIVE_MESSAGE data: $jsonString');
            print("\nReceived incomplete message data from server.");
          }

          break;

        case Constants.ACTION_ROOMS_LIST:
          // ROOMS_LIST comes directly from server (S->C)
          if (data != null && data.containsKey("rooms")) {
            List<dynamic> roomsArray = data["rooms"];
            print("\nYour rooms:");
            if (roomsArray.isEmpty) {
              print("  (No rooms found)");
            } else {
              for (int i = 0; i < roomsArray.length; i++) {
                print("  ${i + 1}. ${roomsArray[i]}");
              }
            }
          } else {
            logger.log('Received invalid ROOMS_LIST data: $jsonString');
            print("\nFailed to retrieve room list from server.");
          }
          break;

        case Constants.ACTION_MESSAGES_LIST:
          // MESSAGES_LIST comes directly from server (S->C)
          if (data != null &&
              data.containsKey("room_id") &&
              data.containsKey("messages")) {
            String roomId = data["room_id"];
            List<dynamic> messagesArray = data["messages"];
            print("\nMessages in room '$roomId':");
            if (messagesArray.isEmpty) {
              print("  (No messages found)");
            } else {
              for (var msgElement in messagesArray) {
                Map<String, dynamic> msgObject = msgElement;
                String sender = msgObject["sender_chatid"];
                String content = msgObject["content"];
                String timestampStr = msgObject["timestamp"];
                String formattedTime =
                    formatTimestamp(timestampStr, "yyyy-MM-dd HH:mm:ss");
                print("  [$formattedTime] $sender: $content");
              }
            }
          } else {
            logger.log('Received invalid MESSAGES_LIST data: $jsonString');
            print("\nFailed to retrieve messages from server.");
          }
          break;

        case Constants.ACTION_GET_USERS:
          if (data != null && data.containsKey("users")) {
            List<dynamic> users = data["users"];
            print("\nUsers in system:");
            if (users.isEmpty) {
              print("  (No users found)");
            } else {
              for (var user in users) {
                print("  - $user");
              }
            }
          }
          break;

        case Constants.ACTION_GET_ROOM_USERS:
          if (data != null &&
              data.containsKey("room_id") &&
              data.containsKey("users")) {
            String roomId = data["room_id"];
            List<dynamic> users = data["users"];
            print("\nUsers in room '$roomId':");
            if (users.isEmpty) {
              print("  (No users found)");
            } else {
              for (var user in users) {
                print("  - $user");
              }
            }
          }
          break;

        case Constants.ACTION_USERS_LIST:
          if (data != null && data.containsKey("users")) {
            List<dynamic> usersArray = data["users"];
            print("\nUsers in the system:");
            if (usersArray.isEmpty) {
              print("  (No users found)");
            } else {
              for (int i = 0; i < usersArray.length; i++) {
                String username = usersArray[i];
                print("  ${i + 1}. $username");
              }
            }
          } else {
            logger.log('Received invalid USERS_LIST data: $jsonString');
            print("\nFailed to retrieve users list from server.");
          }
          break;

        case Constants.ACTION_USER_ADDED:
          if (Constants.STATUS_SUCCESS == status &&
              data != null &&
              data.containsKey(Constants.KEY_ROOM_ID) &&
              data.containsKey("user_added")) {
            String roomId = data[Constants.KEY_ROOM_ID];
            String userAdded = data["user_added"];
            print("\nUser '$userAdded' successfully added to room: $roomId");
          } else {
            print(
                "\nFailed to add user to room: ${message ?? 'Unknown reason'}");
          }
          break;

        case Constants.ACTION_USER_REMOVED:
          if (Constants.STATUS_SUCCESS == status &&
              data != null &&
              data.containsKey(Constants.KEY_ROOM_ID) &&
              data.containsKey("user_removed")) {
            String roomId = data[Constants.KEY_ROOM_ID];
            String userRemoved = data["user_removed"];
            print(
                "\nUser '$userRemoved' successfully removed from room: $roomId");
          } else {
            print(
                "\nFailed to remove user from room: ${message ?? 'Unknown reason'}");
          }
          break;

        case Constants.ACTION_ROOM_DELETED:
          if (Constants.STATUS_SUCCESS == status &&
              data != null &&
              data.containsKey(Constants.KEY_ROOM_ID)) {
            String roomId = data[Constants.KEY_ROOM_ID];
            print("\nRoom '$roomId' successfully deleted.");
          } else {
            print("\nFailed to delete room: ${message ?? 'Unknown reason'}");
          }
          break;

        case Constants.ACTION_ROOM_RENAMED:
          if (Constants.STATUS_SUCCESS == status &&
              data != null &&
              data.containsKey(Constants.KEY_ROOM_ID) &&
              data.containsKey("new_room_name")) {
            String roomId = data[Constants.KEY_ROOM_ID];
            String newRoomName = data["new_room_name"];
            print("\nRoom '$roomId' successfully renamed to '$newRoomName'.");
          } else {
            print("\nFailed to rename room: ${message ?? 'Unknown reason'}");
          }
          break;

        case Constants.ACTION_ROOM_USERS_LIST:
          if (Constants.STATUS_SUCCESS == status &&
              data != null &&
              data.containsKey(Constants.KEY_ROOM_ID) &&
              data.containsKey("users")) {
            String roomId = data[Constants.KEY_ROOM_ID];
            List<dynamic> usersArray = data["users"];
            print("\nUsers in room '$roomId':");
            if (usersArray.isEmpty) {
              print("  (No users found in this room)");
            } else {
              for (int i = 0; i < usersArray.length; i++) {
                String username = usersArray[i];
                print("  ${i + 1}. $username");
              }
            }
          } else {
            print("\nFailed to get room users: ${message ?? 'Unknown reason'}");
          }
          break;

        case Constants.ACTION_REGISTER:
          if (Constants.STATUS_SUCCESS == status && message != null) {
            print("\nRegistration successful: $message");
          } else {
            print("\nRegistration failed: ${message ?? 'Unknown error'}");
          }
          break;

        default:
          logger.log('Unhandled confirmed server action: $action');
          if (message != null) {
            print("\nServer message ($action): $message");
          } else {
            print("\nReceived unhandled action from server: $action");
          }
          break;
      }
      stdout.write("> "); // Prompt for next user input
    } catch (e) {
      logger.log('Error processing confirmed server JSON: $e');
      print("\nError processing message from server.");
      stdout.write("> ");
    }
  }

  String formatTimestamp(String isoTimestamp, String pattern) {
    try {
      DateTime instant = DateTime.parse(isoTimestamp);
      return DateFormat(pattern).format(instant.toLocal());
    } catch (e) {
      logger.log('Failed to parse or format timestamp \'$isoTimestamp\': $e');
      return isoTimestamp; // Return original string if parsing fails
    }
  }
}
