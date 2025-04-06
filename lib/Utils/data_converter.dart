import 'package:finalltmcb/Model/User_model.dart';
import 'package:finalltmcb/Model/ChatMessage.dart';
import 'dart:convert';
import 'package:finalltmcb/ClientUdp/client_state.dart';

class DataConverter {
  static Map<String, dynamic>? processHandshakeData(ClientState clientState, String messageStr) {
    try {
      Map<String, dynamic> messageJson = jsonDecode(messageStr);
      
      if (messageJson['data'] != null) {
        Map<String, dynamic> messageData = messageJson['data'];
        if (messageData.containsKey("all_users")) {
          // Update client state
          clientState.allUsers = List<String>.from(messageData["all_users"]);
          clientState.allMessages = Map<String, List<dynamic>>.from(messageData["all_messages"] ?? {});
          clientState.rooms = List<Map<String, dynamic>>.from(messageData["rooms"]);
          
          // Convert data to required formats
          final users = convertToUsers(clientState.allUsers);
          final cachedMessages = convertToCachedMessages(clientState.allMessages, clientState.rooms);
          final roomMessages = convertToRoomMessages(clientState.allMessages, clientState.allUsers[0]); // Assuming first user is current user
          
          // Store converted data directly in client state
          clientState.convertedUsers = users;
          clientState.cachedMessages = cachedMessages;
          clientState.roomMessages = roomMessages;
          
          return {
            'success': true,
            'message': 'Data converted and stored successfully'
          };
        }
      }
    } catch (e) {
      print("Error processing handshake data: $e");
      return null;
    }
  }

  // Convert list of user IDs to list of User objects
  static List<User> convertToUsers(List<String> userIds) {
    return userIds.map((userId) => User(
      chatId: userId,
      createdAt: DateTime.now(),
    )).toList();
  }

  // Convert raw messages and rooms data to cached message format
  static List<Map<String, dynamic>> convertToCachedMessages(
    Map<String, List<dynamic>> allMessages,
    List<Map<String, dynamic>> rooms
  ) {
    List<Map<String, dynamic>> cachedMessages = [];
    
    // Add room messages
    for (var room in rooms) {
      cachedMessages.add({
        'name': room['name'],
        'message': _getLastMessage(allMessages[room['id']] ?? []),
        'avatar': 'assets/logoS.jpg',
        'isOnline': true,
        'id': room['id'],
        'isGroup': true,
        'members': List<String>.from(room['members']),
      });
    }

    return cachedMessages;
  }

  // Get last message text for display
  static String _getLastMessage(List<dynamic> messages) {
    if (messages.isEmpty) return '';
    var lastMessage = messages.last;
    return lastMessage['content'] ?? '';
  }

  // Convert raw messages to chat messages format per room
  static Map<String, List<ChatMessage>> convertToRoomMessages(
    Map<String, List<dynamic>> allMessages,
    String currentUserId
  ) {
    Map<String, List<ChatMessage>> roomMessages = {};

    allMessages.forEach((roomId, messages) {
      roomMessages[roomId] = messages.map((msg) => ChatMessage(
        text: msg['content'] ?? '',
        isMe: msg['sender_chatid'] == currentUserId,
        timestamp: DateTime.parse(msg['timestamp']),
        image: null,
      )).toList();
    });

    return roomMessages;
  }
}
