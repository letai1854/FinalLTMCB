import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'dart:developer' as logger;
import 'dart:typed_data'; // Import for Uint8List

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
    print("UDP client set in MessageController");
  }

  // Method to send MessageData via UDP
  Future<void> SendMessage(MessageData message) async {
    if (_udpClient == null) {
      print('Error: UDP Client is not initialized.');
      throw Exception('UDP Client không được khởi tạo. Vui lòng thử lại sau.');
    }

    const String separator = '%%%'; // Define the separator
    final List<String> payloadParts = [];

    try {
      // 1. Add Text if exists
      if (message.text != null && message.text!.isNotEmpty) {
        payloadParts.add('Text:${message.text}');
      }

      // 2. Add Images if exist
      if (message.images.isNotEmpty) {
        final imagesJson =
            jsonEncode(message.images.map((e) => e.toJson()).toList());
        final imagesBase64 = base64Encode(utf8.encode(imagesJson));
        payloadParts.add('Images:$imagesBase64');
      }

      // 3. Add Audios if exist
      if (message.audios.isNotEmpty) {
        final audiosJson =
            jsonEncode(message.audios.map((e) => e.toJson()).toList());
        final audiosBase64 = base64Encode(utf8.encode(audiosJson));
        payloadParts.add('Audios:$audiosBase64');
      }

      // 4. Add Files if exist
      if (message.files.isNotEmpty) {
        final filesJson =
            jsonEncode(message.files.map((e) => e.toJson()).toList());
        final filesBase64 = base64Encode(utf8.encode(filesJson));
        payloadParts.add('Files:$filesBase64');
      }

      // 5. Add Video if exists
      if (message.video != null) {
        final videoJson = jsonEncode(message.video!.toJson());
        final videoBase64 = base64Encode(utf8.encode(videoJson));
        payloadParts.add('Video:$videoBase64');
      }

      // 6. Add Timestamp (always present)
      payloadParts.add('Time:${message.timestamp.toIso8601String()}');

      // 7. Join parts and convert to bytes
      final payloadString = payloadParts.join(separator);
      final payloadBytes = utf8.encode(payloadString);
      print("Payload: $payloadString");
      print("Payload bytes: ${payloadBytes} bytes");

      // 8. Send data via UDP client
      // !!! IMPORTANT: Replace 'sendData' with the actual method name in your UdpChatClient class !!!
      // print(
      //     "Sending UDP data (${payloadBytes.length} bytes)... Payload preview: ${payloadString.substring(0, min(payloadString.length, 100))}...");
      // await _udpClient!.sendData(
      //     payloadBytes); // Assuming sendData exists and returns Future<void> or void
      // print("UDP data sent.");
    } catch (e) {
      print("Error sending message via UDP: $e");
      // Optional: Re-throw or handle the error appropriately
      throw Exception('Gửi tin nhắn thất bại: $e');
    }
  }
}
