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

  // Method to send MessageData via UDP
  Future<void> SendMessage(MessageData message) async {
    String roomId = "room1";
    if (roomId.isEmpty) {
      logger.log("Error: Room ID is empty.", name: "MessageController");
      throw Exception("Không thể gửi tin nhắn: ID phòng không hợp lệ.");
    }

    try {
      // 1. Chuyển MessageData thành Map -> JSON String
      //    (Giả định các hàm toJson() của Image/Audio/Video/File đã tự Base64 dữ liệu media)
      final Map<String, dynamic> messageJsonMap = message.toJson();
      final String messageJsonString = jsonEncode(messageJsonMap);
      logger.log(
          "MessageData JSON (Payload): ${messageJsonString.substring(0, min(messageJsonString.length, 150))}...",
          name: "MessageController");

      // 2. --- LOẠI BỎ BƯỚC BASE64 TOÀN BỘ JSON ---
      // final String messagePayloadBase64 = base64Encode(utf8.encode(messageJsonString));
      // logger.log("Message Payload Base64: ${messagePayloadBase64.substring(0, min(messagePayloadBase64.length, 100))}...", name: "MessageController");

      // 3. Tạo chuỗi lệnh: /send <roomId> <rawJsonStringPayload>
      //    Payload bây giờ là chuỗi JSON trực tiếp
      final String commandString = "/send $roomId $messageJsonString";
      // Log cẩn thận vì payload có thể rất dài
      logger.log("Formatted command string using Raw JSON Payload",
          name: "MessageController");
      print(
          "Formatted command string (preview): ${commandString.substring(0, min(commandString.length, 200))}..."); // Log preview dài hơn

      // 4. Gửi lệnh đến CommandProcessor để xử lý tiếp
      logger.log("Passing command to CommandProcessor...",
          name: "MessageController");
      // !!! Đảm bảo CommandProcessor/Handler biết cách trích xuất payload JSON này !!!
      await _udpClient?.commandProcessor.processCommand(commandString);
      logger.log(
          "Command '/send' with Raw JSON Payload passed to CommandProcessor.",
          name: "MessageController");
    } catch (e, stackTrace) {
      logger.log("Error formatting/processing send command with Raw JSON: $e",
          name: "MessageController", error: e, stackTrace: stackTrace);
      throw Exception('Gửi tin nhắn thất bại: $e');
    }
  }

  // *** HÀM GỬI TIN NHẮN VĂN BẢN ***
  Future<void> SendTextMessage(
      String roomId, List<String> members, String messageContent) async {
    logger.log(
        'MessageController: Preparing to send text message to room $roomId');

    // Lấy instance UdpClient (điều chỉnh cách lấy cho phù hợp với cấu trúc của bạn)
    try {
      // !!! THAY THẾ BẰNG CÁCH LẤY INSTANCE UDPCLIENT/CLIENTSTATE ĐÚNG !!!
      // Ví dụ truy cập qua một singleton hoặc GetIt
      // Giả sử UdpClient có một getter static hoặc tương tự để lấy instance đang chạy

      // Cần đảm bảo client đã login và có session key
    } catch (e) {
      logger.log('Error getting UdpClient instance: $e',
          name: 'MessageController');
      throw Exception('Failed to get UDP client instance: $e');
    }

    // Tạo payload dữ liệu theo định dạng yêu cầu của server

    try {
      // Gửi dữ liệu qua UdpClient
      // Hàm sendData của UdpClient sẽ tự động mã hóa và gửi
      // Nó cũng nên xử lý việc chờ ACK hoặc timeout nếu cần
      final String commandString = "/send $roomId $messageContent";
      await _udpClient?.commandProcessor.processCommand(commandString);
      logger.log(
          'MessageController: Text message sent successfully to room $roomId.');
    } catch (e) {
      logger.log('Error sending text message via UdpClient: $e',
          name: 'MessageController');
      // Ném lại lỗi để ChatContent có thể hiển thị thông báo
      throw Exception('Failed to send message: $e');
    }
  }
  // **********************************

  // Các hàm khác của contr
}
