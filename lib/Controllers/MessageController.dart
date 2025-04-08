import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'dart:developer' as logger;
import 'dart:typed_data'; // Import for Uint8List
import 'dart:io' as io; // Import for InternetAddress
import 'dart:isolate'; // Import for Isolate

import 'package:finalltmcb/ClientUdp/command_processor.dart';
import 'package:finalltmcb/ClientUdp/json_helper.dart';
import 'package:finalltmcb/ClientUdp/udp_client_singleton.dart';
import 'package:finalltmcb/File/UdpChatClientFile.dart';
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
  // static final MessageController _instance = MessageController._internal();

  // // Private constructor
  // MessageController._internal();

  // // Factory constructor to return the singleton instance
  // factory MessageController() {
  //   return _instance;
  // }

  static final MessageController _instance = MessageController._internal();

  MessageController._internal();
  factory MessageController() {
    return _instance;
  }
  static MessageController get instance => _instance;
  UdpChatClientFile? _udpChatClientFile;

  // Reference to the UDP client
  UdpChatClient? _udpClient;

  // Add public getter for the UDP client
  UdpChatClient? get udpClient => _udpClient;

  // Set the UDP client reference
  // void setUdpClient(UdpChatClient client, int portFile) {
  //   _udpClient = client;
  //    _udpChatClientFile = await UdpChatClientFile.create(
  //       "localhost", Constants.FILE_TRANSFER_SERVER_PORT, portFile);

  //   // Cần truyền client cho CommandProcessor nếu nó cần
  //   // commandProcessor.setUdpClient(client); // Ví dụ

  //   print("UDP client set in MessageController");
  // }
  Future<void> setUdpClient(UdpChatClient client, int portFile) async {
    try {
      _udpClient = client;

      // Create UdpChatClientFile asynchronously
      _udpChatClientFile = await UdpChatClientFile.create(
          "localhost", Constants.FILE_TRANSFER_SERVER_PORT, portFile);
      _udpChatClientFile?.messageListener.startListening();
      logger.log("UDP clients initialized successfully");
    } catch (e) {
      logger.log("Error initializing UDP clients: $e");
      throw Exception('Failed to initialize UDP clients: $e');
    }
    // void setUdpChatClientFile(UdpChatClientFile client) {
    //   _udpChatClientFile = client;
    // }
  }

  UdpChatClientFile? get udpChatClientFile => _udpChatClientFile;

  // Add new properties for file transfer isolate
  Isolate? _fileTransferIsolate;
  ReceivePort? _receivePort;

  // Method to send MessageData via UDP
  Future<void> SendFileMessage(String chat_id, String room_id, String file_path,
      int file_Size, String file_type, int totalPackage) async {
    String host = "localhost"; // Change this to your actual server IP
    int port = Constants
        .FILE_TRANSFER_SERVER_PORT; // Make sure this matches your server's file transfer port

    try {
      // Extract file extension from path
      String fileExtension = file_path.split('.').last;
      if (fileExtension.isEmpty) {
        throw Exception("File has no extension: $file_path");
      }

      // Get full file path and verify file
      final file = io.File(file_path);
      if (!await file.exists()) {
        throw Exception("File not found: $file_path");
      }

      final actualFileSize = await file.length();
      final actualTotalPackages = (actualFileSize / (1024 * 32)).ceil();

      logger.log("File details:");
      logger.log("Path: $file_path");
      logger.log("Extension: .$fileExtension");
      logger.log("Actual size: $actualFileSize bytes");
      logger.log("Calculated packages: $actualTotalPackages");

      // Create a ReceivePort for communication
      _receivePort = ReceivePort();

      try {
        final String commandString =
            "/file $room_id $chat_id $file_path $file_Size $file_type $totalPackage";
        final fileClient = MessageController._instance?._udpChatClientFile;
        fileClient?.commandProcessor
            .processCommand(commandString, fileClient.handshakeManager);
      } catch (e) {}

      // Create the isolate with correct server details
      // _fileTransferIsolate = await Isolate.spawn(
      //   _fileTransferHandler,
      //   {
      //     'sendPort': _receivePort!.sendPort,
      //     'host': host,
      //     'port': port,
      //     'chatId': chat_id,
      //     'roomId': room_id,
      //     'filePath': file_path,
      //     'fileSize': actualFileSize,
      //     'fileType': '$file_type.$fileExtension',
      //     'totalPackage': actualTotalPackages,
      //   },
      // );

      // Listen for responses from the file transfer isolate
      // _receivePort!.listen((dynamic message) {
      //   if (message is Map) {
      //     if (message['status'] == 'completed') {
      //       logger.log('File transfer completed successfully');
      //       _cleanupFileTransfer();
      //     } else if (message['status'] == 'error') {
      //       logger.log('File transfer error: ${message['error']}');
      //       _cleanupFileTransfer();
      //     }
      //   }
      // });
    } catch (e) {
      logger.log("Error in SendFileMessage: $e");
      throw Exception("Failed to process file: $e");
    }
  }

  void _cleanupFileTransfer() {
    _fileTransferIsolate?.kill();
    _receivePort?.close();
    _fileTransferIsolate = null;
    _receivePort = null;
  }

  // *** HÀM GỬI TIN NHẮN VĂN BẢN ***
  Future<void> SendTextMessage(
      String roomId, List<String> members, String messageContent) async {
    logger.log(
        'MessageController: Preparing to send text message to room $roomId');

    // Lấy instance UdpClient (điều chỉnh cách lấy cho phù hợp với cấu trúc của bạn)
    try {
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
}

// Isolate handler function - runs in separate thread
void _fileTransferHandler(Map<String, dynamic> params) async {
  final SendPort sendPort = params['sendPort'];
  final String host = params['host'];
  final int port = params['port'];
  final String roomId = params['roomId'];
  final String chat_id = params['chatId'];
  final String file_path = params['filePath'];
  final int file_Size = params['fileSize'];
  final String file_type = params['fileType'];
  final int totalPackage = params['totalPackage'];

  try {
    // Create UDP client in the new isolate
    // int portFile = UdpClientSingleton().clientState?.portFile ?? 0;
    // final clientFile = await UdpChatClientFile.create(host, port, portFile);

    final String commandString =
        "/file $roomId $chat_id $file_path $file_Size $file_type $totalPackage";
    // Prepare the command string with file detailscli
    // var clientFile = udpChatClientFile; // Use the getter
    final fileClient = MessageController._instance?._udpChatClientFile;
    fileClient?.commandProcessor
        .processCommand(commandString, fileClient.handshakeManager);
    // if (clientFile != null) {
    //   clientFile.commandProcessor
    //       .processCommand(commandString, clientFile.handshakeManager);
    // }
    // Start the client and check result
    // final bool started = await fileClient?.start();
    // if (!started) {
    //   throw Exception('Failed to start file client');
    // }

    // sendPort.send({'status': 'completed'});

    // Cleanup
    // clientFile.close();
  } catch (e) {
    // Send error message back to main isolate
    sendPort.send({
      'status': 'error',
      'error': e.toString(),
    });
  }
}

class _udpClient {}
