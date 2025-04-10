import 'package:finalltmcb/ClientUdp/udp_client_singleton.dart';
import 'package:finalltmcb/File/Core/file_handshake_manager.dart';
import 'package:finalltmcb/Model/ChatMessage.dart';
import 'package:finalltmcb/Model/FileTransferQueue.dart';
import 'package:finalltmcb/Model/VideoFileMessage.dart';
import 'package:finalltmcb/Service/FileDownloadNotifier.dart';
import 'package:finalltmcb/Service/MessageNotifier.dart';
import 'package:finalltmcb/Widget/FilePickerUtil.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as logger;
import 'package:mime/mime.dart';

import '../ClientStateForFile.dart';
import '../Handlers/base_handler.dart';
import '../Handlers/file_handler.dart';
import '../Handlers/image_handler.dart';
import '../Handlers/video_handler.dart';
import '../Handlers/audio_handler.dart';
import '../Models/file_constants.dart';

class FileCommandProcessor {
  final ClientStateForFile clientState;
  final Map<String, BaseHandler> handlers = {};

  FileCommandProcessor(this.clientState, handshakeManager) {
    _initializeHandlers();
  }

  void _initializeHandlers() {
    handlers['file'] = FileHandler();
    handlers['image'] = ImageHandler();
    handlers['video'] = VideoHandler();
    handlers['audio'] = AudioHandler();
  }

  Future<void> processCommand(
      String command, FileHandshakeManager handshakemanager) async {
    final parts = command.split(' ');
    if (parts.length < 7) {
      print(
          'Invalid command format. Expected: /file roomId chatId filePath fileSize fileType totalPackage');
      return;
    }

    final type = parts[0].substring(1); // Remove '/'
    final roomId = parts[1];
    final chatId = parts[2];
    // Reconstruct filePath from remaining parts
    final filePath = parts.sublist(3, parts.length - 3).join(' ');
    final fileSize = int.tryParse(parts[parts.length - 3]) ?? 0;
    final fileType = parts[parts.length - 2];
    final totalPackages = int.tryParse(parts[parts.length - 1]) ?? 0;

    final handler = handlers[type];
    if (handler != null) {
      await handler.handle(
          roomId: roomId,
          chatId: chatId,
          filePath: filePath,
          fileSize: fileSize,
          fileType: fileType,
          totalPackages: totalPackages,
          handshakeManager: handshakemanager);
    }
  }

  Future<void> processCommandDownload(
      String command, FileHandshakeManager handshakemanager) async {
    final parts = command.split(' ');
    if (parts.length < 3) {
      print('Invalid command format. Expected: /download roomId filePath');
      return;
    }

    final type = parts[0].substring(1); // Remove '/'
    final roomId = parts[1];
    // Get everything after roomId as filename to preserve spaces
    final filename = parts.sublist(2).join(' ').trim();

    final Map<String, dynamic> downloadRequest = {
      'action': FileConstants.ACTION_FILE_DOWNLOAD_REQ,
      'data': {'room_id': roomId, 'file_name': filename}
    };
    await handshakemanager.InitFileDownload(downloadRequest);
  }
}

class FileDownloadProcessor {
  Map<String, Map<int, List<int>>> fileChunks = {};
  Map<String, int> expectedPackets = {};
  Map<String, int> totalFileSize = {};

  void handleDownloadMeta(Map<String, dynamic> data) {
    final String roomId = data['room_id'];
    final String filePath = data['file_path'];
    final int fileSize = data['file_size'];
    final int totalPackets = data['total_packets'];

    String fileKey = '${roomId}_$filePath';
    fileChunks[fileKey] = {};
    expectedPackets[fileKey] = totalPackets;
    totalFileSize[fileKey] = fileSize;

    logger.log(
        '📝 Initialized download for $filePath with $totalPackets packets');
  }

  Future<void> handleDownloadData(Map<String, dynamic> data) async {
    final String roomId = data['room_id'];
    // Thống nhất sử dụng file_name hoặc file_path
    final String fileName = data['file_name'] ?? data['file_path'];
    if (fileName == null) {
      logger.log('❌ Missing file name/path in download data');
      return;
    }

    final int sequenceNumber = data['sequence_number'];
    final int chunkSize = data['chunk_size'];
    final String base64Data = data['file_data'];

    // Sử dụng fileName làm key
    String fileKey = '${roomId}_$fileName';

    if (!fileChunks.containsKey(fileKey)) {
      logger.log('❌ No initialized download for $fileName');
      return;
    }

    // Log chunk details
    logger.log('📦 Processing chunk:');
    logger.log('File: $fileName');
    logger.log('Sequence: $sequenceNumber');
    logger.log('Chunk size: $chunkSize bytes');

    // Decode and store chunk
    List<int> decodedData = base64Decode(base64Data);
    if (decodedData.length != chunkSize) {
      logger.log(
          '⚠️ Chunk size mismatch! Expected: $chunkSize, Got: ${decodedData.length}');
    }

    fileChunks[fileKey]![sequenceNumber] = decodedData;
    logger.log('✅ Received chunk $sequenceNumber for $fileName');
  }

  Future<void> handleDownloadFinish(Map<String, dynamic> data) async {
    final String roomId = data['room_id'];
    final String filePath = data['file_path'];
    String fileKey = '${roomId}_$filePath';

    if (!fileChunks.containsKey(fileKey)) {
      logger.log('❌ No data found for $filePath');
      return;
    }

    try {
      // Kiểm tra đã nhận đủ chunks chưa
      final int expectedTotal = expectedPackets[fileKey] ?? 0;
      final int receivedTotal = fileChunks[fileKey]?.length ?? 0;

      logger.log('📊 Checking chunks completeness:');
      logger.log('Expected chunks: $expectedTotal');
      logger.log('Received chunks: $receivedTotal');

      if (receivedTotal < expectedTotal) {
        logger.log(
            '❌ Missing chunks: ${expectedTotal - receivedTotal} chunks missing');
        // Có thể thêm logic yêu cầu gửi lại các chunks bị thiếu ở đây
        return;
      }

      // Tạo file hoàn chỉnh từ chunks
      List<int> completeFile = [];
      var chunks = fileChunks[fileKey]!;
      var sortedKeys = chunks.keys.toList()..sort();

      // Log chi tiết về các chunks
      logger.log('📦 Processing chunks in order:');
      for (var key in sortedKeys) {
        logger.log('Processing chunk $key, size: ${chunks[key]!.length} bytes');
        completeFile.addAll(chunks[key]!);
      }

      // Kiểm tra kích thước file cuối cùng
      final expectedSize = totalFileSize[fileKey] ?? 0;
      if (completeFile.length != expectedSize) {
        logger.log(
            '⚠️ Size mismatch! Expected: $expectedSize, Got: ${completeFile.length}');
      }

      // Lưu file
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory(); // Android specific
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not get storage directory');
      }

      final fileName = filePath.split('/').last;
      final String fullPath = '${directory.path}/Downloads';

      // Tạo thư mục Downloads nếu chưa tồn tại
      await Directory(fullPath).create(recursive: true);

      final file = File('$fullPath/$fileName');
      await file.writeAsBytes(completeFile);

      logger.log('✅ File saved successfully to: ${file.path}');
      logger.log('📁 File size: ${await file.length()} bytes');

      // After file is successfully saved
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

      // Create appropriate message based on file type
      ChatMessage newMessage = ChatMessage(
        isMe: false,
        timestamp: DateTime.now(),
        text: '', // Add required text parameter
      );

      if (mimeType.startsWith('image/')) {
        newMessage = ChatMessage(
          text: '', // Required
          isMe: false,
          timestamp: DateTime.now(),
          image: base64Encode(completeFile),
          mimeType: mimeType,
        );
      } else if (mimeType.startsWith('video/')) {
        newMessage = ChatMessage(
          text: '', // Required
          isMe: false,
          timestamp: DateTime.now(),
          video: VideoFileMessage(
            fileName: fileName,
            mimeType: mimeType,
            fileSize: completeFile.length,
            base64Data: '',
            localPath: file.path,
          ),
        );
      } else if (mimeType.startsWith('audio/')) {
        newMessage = ChatMessage(
          text: '', // Required
          isMe: false,
          timestamp: DateTime.now(),
          audio: file.path,
          isAudioPath: true,
        );
      } else {
        newMessage = ChatMessage(
          text: '', // Required
          isMe: false,
          timestamp: DateTime.now(),
          file: FileMessage(
            fileName: fileName,
            mimeType: mimeType,
            fileSize: completeFile.length,
            filePath: file.path,
            totalPackages: expectedTotal,
            fileType: 'file',
          ),
        );
      }
      
      // Check if there's an existing placeholder message to update
      var messageExists = false;
      
      if (UdpClientSingleton().clientState != null) {
        var messages = UdpClientSingleton().clientState?.allMessagesConverted[roomId];
        
        if (messages != null) {
          // Try to find a matching file_path message placeholder
          for (var i = 0; i < messages.length; i++) {
            if (messages[i].text.startsWith("file_path ") &&  messages[i].text.contains(fileName)) {
              // Found a placeholder, update using the MessageNotifier
              messageExists = true;
              // Pass fileName (not roomId) as the first parameter
              MessageNotifier.updateChatPubble(fileName, newMessage);
              logger.log('✅ Updated existing chat bubble for file: $fileName in room: $roomId');
              break;
            }
          }
        }
      }
      
      // If no placeholder was found, send as a new message
      if (!messageExists) {
        MessageNotifier.updateRecieveFile({
          'roomId': roomId,
          'type': mimeType,
        });
        
        // Notify UI about new file
        FileDownloadNotifier.instance.updateFileDownload({
          'roomId': roomId,
          'message': newMessage,
          'filePath': file.path,
        });
      }

      // Cleanup
      fileChunks.remove(fileKey);
      expectedPackets.remove(fileKey);
      totalFileSize.remove(fileKey);

      // Reset transfer state
      FileTransferState.instance.isTransferring = false;
      FileTransferQueue.instance.removeFirst();
    } catch (e, stackTrace) {
      logger.log('❌ Error saving file: $e');
      logger.log('Stack trace: $stackTrace');
      FileTransferState.instance.isTransferring = false;
    }
  }
}
