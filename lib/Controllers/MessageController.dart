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
import 'package:finalltmcb/File/Models/file_constants.dart';
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
  static final MessageController _instance = MessageController._internal();

  MessageController._internal();
  factory MessageController() {
    return _instance;
  }
  static MessageController get instance => _instance;
  UdpChatClientFile? _udpChatClientFile;

  // Reference to the UDP client
  UdpChatClient? _udpClient;

  UdpChatClient? get udpClient => _udpClient;

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
  }

  UdpChatClientFile? get udpChatClientFile => _udpChatClientFile;

  Isolate? _fileTransferIsolate;
  ReceivePort? _receivePort;

  Future<void> SendFileMessage(
      String tatus,
      String chat_id,
      String room_id,
      String file_path,
      int file_Size,
      String file_type,
      int totalPackage) async {
    try {
      // Extract file extension from path
      String fileExtension = file_path.split('.').last;
      if (fileExtension.isEmpty) {
        throw Exception("File has no extension: $file_path");
      }

      // Get full file path and verify file
      // final file = io.File(file_path);
      // if (!await file.exists()) {
      //   throw Exception("File not found: $file_path");
      // }

      // final actualFileSize = await file.length();
      // final actualTotalPackages = (actualFileSize / (1024 * 32)).ceil();
      // Create a ReceivePort for communication

      try {
        final String commandString =
            "/file $room_id $chat_id $file_path $file_Size $file_type $totalPackage";
        final fileClient = MessageController._instance?._udpChatClientFile;
        fileClient?.commandProcessor
            .processCommand(commandString, fileClient.handshakeManager);
      } catch (e) {}
    } catch (e) {
      logger.log("Error in SendFileMessage: $e");
      throw Exception("Failed to process file: $e");
    }
  }

  Future<void> DownloadFileMessage(String chat_id, String room_id,
      String file_path, String file_type) async {
    try {
      final String commandString = "/download $room_id $file_path";

      final fileClient = MessageController._instance?._udpChatClientFile;
      await fileClient?.commandProcessor
          .processCommandDownload(commandString, fileClient.handshakeManager);
    } catch (e) {
      logger.log("Error in DownloadFileMessage: $e");
      throw Exception("Failed to download file: $e");
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
    final String commandString =
        "/file $roomId $chat_id $file_path $file_Size $file_type $totalPackage";

    final fileClient = MessageController._instance?._udpChatClientFile;
    fileClient?.commandProcessor
        .processCommand(commandString, fileClient.handshakeManager);
  } catch (e) {
    sendPort.send({
      'status': 'error',
      'error': e.toString(),
    });
  }
}

class _udpClient {}
