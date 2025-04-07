import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as logger;
import 'package:finalltmcb/File/Core/file_json_helper.dart';

import '../Models/file_constants.dart';
import '../ClientStateForFile.dart';
import '../Core/file_handshake_manager.dart';

class FileMessageListener {
  final ClientStateForFile clientState;
  final FileHandshakeManager handshakeManager;
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
        default:
          logger.log('❓ [FileListener] Unknown action: $action');
      }
    } catch (e) {
      logger.log('❌ [FileListener] Error processing packet: $e');
    }
  }

  void _handleFileInit(Map<String, dynamic> response) {
    // Handle file initialization
  }

  void _handleFileData(Map<String, dynamic> response) {
    // Handle file data chunks
  }

  void _handleFileFin(Map<String, dynamic> response) {
    // Handle file transfer completion
  }
}
