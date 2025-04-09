import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as logger;
import 'dart:math';
import 'package:finalltmcb/File/Core/file_command_processor.dart';
import 'package:finalltmcb/File/Core/file_json_helper.dart';
import 'package:finalltmcb/Model/FileTransferQueue.dart';

import '../Models/file_constants.dart';
import '../ClientStateForFile.dart';
import '../Core/file_handshake_manager.dart';

class FileMessageListener {
  final ClientStateForFile clientState;
  final FileHandshakeManager handshakeManager;
  final FileDownloadProcessor _downloadProcessor = FileDownloadProcessor();
  bool isListening = false;
  StreamSubscription<RawSocketEvent>? _subscription;

  FileMessageListener(this.clientState, this.handshakeManager);

  void startListening() {
    logger.log('👂 [FileListener] Starting file transfer listener');
    isListening = true;
    _subscription = clientState.socket.listen((event) {
      if (event == RawSocketEvent.read) {
        logger.log('📨 [FileListener] Received data packet');
        final datagram = clientState.socket.receive();
        if (datagram != null) {
          _processPacket(datagram);
        }
      }
    });
    logger.log('✅ [FileListener] Listener initialized successfully');
  }

  void stopListening() {
    logger.log('🛑 [FileListener] Stopping file transfer listener');
    isListening = false;
    _subscription?.cancel();
    logger.log('✅ [FileListener] Listener stopped successfully');
  }

  void _processPacket(Datagram datagram) {
    try {
      logger.log(
          '🔄 [FileListener] Processing packet from ${datagram.address.address}:${datagram.port}');
      final decodedString = FileJsonHelper.safelyDecodeData(datagram.data);
      if (decodedString == null) {
        print('Failed to decode datagram data');
        return;
      }

      final decodedMessage = FileJsonHelper.decodeMessage(decodedString);
      if (decodedMessage == null) {
        print('Failed to decode message');
        return;
      }

      final Map<String, dynamic> response = decodedMessage;
      final String? action = response['action'] as String?;

      if (action == null) {
        print('Invalid action in response');
        return;
      }

      logger.log('📦 [FileListener] Processing action: $action');
      switch (action) {
        case FileConstants.ACTION_FILE_INIT:
          logger.log('🎬 [FileListener] Handling file initialization');
          _handleFileInit(response);
          break;
        case FileConstants.ACTION_FILE_DATA:
          logger.log('📤 [FileListener] Handling file data chunk');
          _handleFileData(response);
          break;
        case FileConstants.ACTION_FILE_FIN:
          logger.log('🏁 [FileListener] Handling file transfer completion');
          _handleFileFin(response);
          break;
        case FileConstants.ACTION_RECIEVE_FILE:
          logger.log('📥 [FileListener] Handling file reception');
          _handleFileReceive(response);
        // Handle file reception logic here
        case FileConstants.ACTION_FILE_DOWNLOAD_REQ:
          logger.log('📥 [FileListener] Handling file download request');
          _handlerDownReq(response);
          break;
        case FileConstants.ACTION_FILE_DOWN_META:
          logger.log('🏁 [FileListener] Handling file download Meta');
          _handleFileDownMeta(response);
          break;
        case FileConstants.ACTION_FILE_DOWN_DATA:
          logger.log('🏁 [FileListener] Handling file download data');
          _handleFileDownData(response);
          break;
        case FileConstants.ACTION_FILE_DOWN_FIN:
          logger.log('🏁 [FileListener] Handling file download fin');
          _handleFileDownFin(response);
          break;
        default:
          logger.log('❓ [FileListener] Unknown action: $action');
      }
    } catch (e) {
      logger.log('❌ [FileListener] Error processing packet: $e');
    }
  }

  void _handleFileInit(Map<String, dynamic> response) {
    // Handle file initialization
    print('File initialization response: $response');
    final data = response['data'];
    // This method should handle the *response* to the initial request,
    // not re-initiate the transfer. Call the handshake manager's
    // response handler instead.
    handshakeManager.handleResponse(response);
  }

  void _handleFileData(Map<String, dynamic> response) {
    // Handle file data chunks
    handshakeManager.sendRemainingChunks(response);
  }

  void _handleFileFin(Map<String, dynamic> response) {
    try {
      if (response['status'] == 'success') {
        logger.log('✅ File transfer completed successfully');
        // Reset the transfer state and remove from queue
        FileTransferQueue.instance.removeFirst();
        FileTransferState.instance.isTransferring = false;
      } else {
        logger.log('❌ File transfer failed');
        FileTransferState.instance.isTransferring = false;
      }
    } catch (e) {
      logger.log('Error handling file completion: $e');
      FileTransferState.instance.isTransferring = false;
    }
  }

  void _handlerDownReq(Map<String, dynamic> response) {
    if (response['status'] == 'error') {
      logger.log('❌ File download request failed');
      FileTransferQueue.instance.removeFirst();
      FileTransferState.instance.isTransferring = false;
    }
  }

  void _handleFileReceive(Map<String, dynamic> response) {
    try {
      logger.log('📥 [FileListener] Processing file reception: $response');

      if (response.containsKey('data')) {
        final data = response['data'] as Map<String, dynamic>;
        final String content = data['content'] ?? '';

        // Extract file path using regex to handle spaces correctly
        final filePathMatch =
            RegExp(r'file_path\s+(.*?)\s+(?:chat_id|room_id|file_type)')
                .firstMatch(content);
        final String filePath = filePathMatch?.group(1)?.trim() ?? '';

        // Extract other fields
        final String chatId = data['chat_id'] ?? '';
        final String roomId = data['room_id'] ?? '';
        final String fileType = RegExp(r'file_type\s+(\S+)')
                .firstMatch(content)
                ?.group(1)
                ?.trim() ??
            '';

        logger.log('Parsed File Information:');
        logger.log('File Path: $filePath');
        logger.log('Chat ID: $chatId');
        logger.log('Room ID: $roomId');
        logger.log('File Type: $fileType');

        if (filePath.isNotEmpty) {
          final item = FileTransferItem(
              status: FileConstants.Action_Status_File_Download,
              currentChatId: chatId,
              userId: roomId,
              filePath: filePath,
              actualFileSize: 0,
              fileType: fileType,
              actualTotalPackages: 0);

          FileTransferQueue.instance.addToQueue(item);
        } else {
          logger
              .log('❌ [FileListener] Could not extract file path from content');
        }
      }
    } catch (e, stackTrace) {
      logger.log('❌ [FileListener] Error handling file reception: $e');
      logger.log('Stack trace: $stackTrace');
    }
  }

  void _handleFileDownMeta(Map<String, dynamic> response) {
    if (response['data'] != null) {
      _downloadProcessor.handleDownloadMeta(response['data']);
    }
  }

  void _handleFileDownData(Map<String, dynamic> response) {
    if (response['data'] != null) {
      _downloadProcessor.handleDownloadData(response['data']);
    }
  }

  void _handleFileDownFin(Map<String, dynamic> response) {
    if (response['data'] != null) {
      _downloadProcessor.handleDownloadFinish(response['data']);
    }
  }
}
