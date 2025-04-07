import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'dart:developer' as logger;
import 'dart:typed_data'; // Import for Uint8List
import 'dart:io'; // Import for InternetAddress

import 'package:finalltmcb/ClientUdp/command_processor.dart';
import 'package:finalltmcb/ClientUdp/json_helper.dart';
import 'package:finalltmcb/Model/ChatMessage.dart';
import 'package:finalltmcb/Model/User_model.dart';
import 'package:finalltmcb/Provider/UserProvider.dart';
import 'package:finalltmcb/constants/constants.dart';
import 'package:http/http.dart' as http;
import 'package:finalltmcb/ClientUdp/udpmain.dart'; // Import UdpChatClient
import 'package:finalltmcb/ClientUdp/constants.dart';
import 'package:finalltmcb/Model/MessageData.dart'; // Import MessageData
// Import other necessary models if they are not implicitly imported via MessageData
import 'package:finalltmcb/Model/ImageMessage.dart';
import 'package:finalltmcb/Model/AudioMessage.dart';
import 'package:finalltmcb/Model/VideoFileMessage.dart';
import 'package:universal_html/html.dart';

// --- GIẢ SỬ BẠN CÓ CÁCH TRUY CẬP COMMAND PROCESSOR ---
// Ví dụ:

class MessageController {
  // Create a singleton instance of UserController
  static final MessageController _instance = MessageController._internal();

  // Private constructor
  MessageController._internal();

  // Factory constructor to return the singleton instance
  factory MessageController() {
    return _instance;
  }

  // Reference to the UDP client
  UdpChatClient? _udpClient;

  // Add public getter for the UDP client
  UdpChatClient? get udpClient => _udpClient;

  // Set the UDP client reference
  void setUdpClient(UdpChatClient client) {
    _udpClient = client;
    // Cần truyền client cho CommandProcessor nếu nó cần
    // commandProcessor.setUdpClient(client); // Ví dụ
    print("UDP client set in MessageController");
  }

  // *** HÀM GỬI TIN NHẮN VĂN BẢN ***
  Future<void> SendTextMessage(String roomId, List<String> members, String messageContent) async {
    // Kiểm tra roomId có hợp lệ không
    if (roomId.isEmpty) {
      logger.log("Error: Room ID is empty.", name: "MessageController");
      throw Exception("Không thể gửi tin nhắn: ID phòng không hợp lệ.");
    }
    
    logger.log(
        'MessageController: Preparing to send text message to room $roomId');

    // Lấy instance UdpClient
    try {
      UdpChatClient? _udpClient = _instance.udpClient;
      
      if (_udpClient == null) {
        throw Exception("Không thể kết nối đến máy chủ chat");
      }

      // Gửi dữ liệu qua UdpClient - sử dụng roomId được truyền vào từ tham số
      final String commandString = "/send $roomId $messageContent";
      logger.log('Sending command: $commandString');
      
      await _udpClient.commandProcessor.processCommand(commandString);
      logger.log(
          'MessageController: Text message sent successfully to room $roomId.');
    } catch (e) {
      logger.log('Error sending text message via UdpClient: $e',
          name: "MessageController");
      // Ném lại lỗi để ChatContent có thể hiển thị thông báo
      throw Exception('Failed to send message: $e');
    }
  }
  
  // Phương thức gửi MessageData phức tạp qua UDP (sẽ thực hiện sau)
  Future<void> SendComplexMessage(String roomId, MessageData message) async {
    // Kiểm tra roomId có hợp lệ không
    if (roomId.isEmpty) {
      logger.log("Error: Room ID is empty.", name: "MessageController");
      throw Exception("Không thể gửi tin nhắn: ID phòng không hợp lệ.");
    }

    try {
      // 1. Chuyển MessageData thành Map -> JSON String
      final Map<String, dynamic> messageJsonMap = message.toJson();
      final String messageJsonString = jsonEncode(messageJsonMap);
      logger.log(
          "MessageData JSON (Payload): ${messageJsonString.substring(0, min(messageJsonString.length, 150))}...",
          name: "MessageController");

      // 2. Tạo chuỗi lệnh với roomId từ tham số
      final String commandString = "/send $roomId $messageJsonString";
      
      // 3. Gửi lệnh đến CommandProcessor
      logger.log("Passing command to CommandProcessor...",
          name: "MessageController");
      await _udpClient?.commandProcessor.processCommand(commandString);
      logger.log(
          "Command '/send' with JSON Payload passed to CommandProcessor.",
          name: "MessageController");
    } catch (e, stackTrace) {
      logger.log("Error formatting/processing send command with JSON: $e",
          name: "MessageController", error: e, stackTrace: stackTrace);
      throw Exception('Gửi tin nhắn thất bại: $e');
    }
  }
  // **********************************

  // Các hàm khác của controller có thể thêm vào đây
}
