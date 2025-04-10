import 'package:finalltmcb/Model/User_model.dart';
import 'package:finalltmcb/Model/ChatMessage.dart';
import 'dart:convert';
import 'package:finalltmcb/ClientUdp/client_state.dart';

class DataConverter {
  static Map<String, dynamic>? processHandshakeData(
      ClientState clientState, String messageStr) {
    try {
      Map<String, dynamic> messageJson = jsonDecode(messageStr);

      if (messageJson['data'] != null) {
        Map<String, dynamic> messageData = messageJson['data'];
        if (messageData.containsKey("all_users")) {
          // Update client state
          clientState.allUsers = List<String>.from(messageData["all_users"]);
          clientState.allMessages = Map<String, List<dynamic>>.from(
              messageData["all_messages"] ?? {});
          clientState.rooms =
              List<Map<String, dynamic>>.from(messageData["rooms"]);

          // Get the current user ID (use the first user from allUsers if currentChatId is null)
          String userIdToUse = clientState.currentChatId ??
              (clientState.allUsers.isNotEmpty ? clientState.allUsers[0] : '');

          // Convert data to required formats
          final users = convertToUsers(clientState.allUsers, userIdToUse);
          final cachedMessages = convertToCachedMessages(
              clientState.allMessages, clientState.rooms);
          final roomMessages =
              convertToRoomMessages(clientState.allMessages, userIdToUse);
          final allMessagesConverted = convertAllMessagesToChatFormat(
              clientState.allMessages, userIdToUse);

          // Store converted data directly in client state
          clientState.convertedUsers = users;
          clientState.cachedMessages = cachedMessages;
          clientState.roomMessages = roomMessages;
          clientState.allMessagesConverted = allMessagesConverted;

          return {
            'success': true,
            'message': 'Data converted and stored successfully'
          };
        }
      }
      return null; // Return null if data wasn't handled
    } catch (e) {
      print("Error processing handshake data: $e");
      return null;
    }
  }

  // Convert list of user IDs to list of User objects, excluding the current user ID
  static List<User> convertToUsers(List<String> userIds, String currentUserId) {
    return userIds
        .where((userId) =>
            userId != currentUserId) // Filter out the current user ID
        .map((userId) => User(
              chatId: userId,
              createdAt: DateTime.now(),
            ))
        .toList();
  }

  // Convert raw messages and rooms data to cached message format

  static List<Map<String, dynamic>> convertToCachedMessages(
      Map<String, List<dynamic>> allMessages,
      List<Map<String, dynamic>> rooms) {
    List<Map<String, dynamic>> cachedMessages = [];
    print(allMessages);

    // Add room messages
    for (var room in rooms) {
      String text = _getLastMessage(allMessages[room['id']] ?? []);
      String content = GetContent(text);

      cachedMessages.add({
        'name': room['name'],
        'message': content,
        'avatar': 'assets/logoS.jpg',
        'isOnline': true,
        'id': room['id'],
        'isGroup': true,
        'members': List<String>.from(room['members']),
      });
    }

    return cachedMessages;
  }

  static String GetContent(String content) {
    // Check if content is empty
    if (content.isEmpty) return 'Phòng mới được tạo';

    // Check for file type indicators at the end of the content
    if (content.toLowerCase().endsWith('image')) {
      return 'Có hình ảnh mới';
    } else if (content.toLowerCase().endsWith('video')) {
      return 'Có video mới';
    } else if (content.toLowerCase().endsWith('audio')) {
      return 'Có bản ghi âm mới';
    } else if (content.toLowerCase().endsWith('file')) {
      return 'Có tập tin mới';
    }

    // If no special type is detected, return the original content
    return content;
  }

  // Convert messages to the format {roomid: [ChatMessage], roomid: [ChatMessage]}
  static Map<String, List<ChatMessage>> convertAllMessagesToChatFormat(
      Map<String, List<dynamic>> allMessages, String currentUserId) {
    Map<String, List<ChatMessage>> result = {};

    allMessages.forEach((roomId, messages) {
      if (messages.isEmpty) {
        // For empty rooms, add an empty list
        result[roomId] = [];
      } else {
        // Process messages for the room
        result[roomId] = messages.map((msg) {
          String content = msg['content'] ?? '';
          String text = content;
          String? image;

          // Check if content is a JSON string
          if (content.startsWith('{') && content.contains('text')) {
            try {
              Map<String, dynamic> jsonContent = jsonDecode(content);
              text = jsonContent['text'] ?? '';

              // Check if there are images in the JSON
              if (jsonContent['images'] != null &&
                  jsonContent['images'] is List &&
                  (jsonContent['images'] as List).isNotEmpty) {
                image = (jsonContent['images'] as List).first.toString();
              }
            } catch (e) {
              print("Error parsing JSON content: $e");
              // Keep the original content if parsing fails
            }
          }

          return ChatMessage(
            text: text,
            isMe: msg['sender_chatid'] == currentUserId,
            timestamp: DateTime.parse(msg['timestamp']),
            image: image,
            name: msg['sender_chatid'],
          );
        }).toList();
      }
    });

    return result;
  }

  // Get last message text for display
  static String _getLastMessage(List<dynamic> messages) {
    if (messages.isEmpty) return '';
    var lastMessage = messages.last;
    return lastMessage['content'] ?? '';
  }

  // Convert raw messages to chat messages format per room
  static Map<String, List<ChatMessage>> convertToRoomMessages(
      Map<String, List<dynamic>> allMessages, String currentUserId) {
    Map<String, List<ChatMessage>> roomMessages = {};

    allMessages.forEach((roomId, messages) {
      roomMessages[roomId] = messages
          .map((msg) => ChatMessage(
                text: msg['content'] ?? '',
                isMe: msg['sender_chatid'] == currentUserId,
                timestamp: DateTime.parse(msg['timestamp']),
                image: null,
              ))
          .toList();
    });

    return roomMessages;
  }
}
