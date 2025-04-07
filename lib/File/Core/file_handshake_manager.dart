import 'dart:async';
import 'dart:developer' as logger;
import '../ClientStateForFile.dart';
import '../Models/file_constants.dart';
import 'file_json_helper.dart';

class FileHandshakeManager {
  final ClientStateForFile clientState;
  final Map<String, Completer<bool>> _pendingTransfers = {};

  FileHandshakeManager(this.clientState);

  Future<bool> initiateFileTransfer(Map<String, dynamic> request) async {
    try {
      // Extract transfer details from request
      final data = request['data'];
      final transferId = DateTime.now().millisecondsSinceEpoch.toString();
      final chatId = data[FileConstants.KEY_CHAT_ID];
      final roomId = data[FileConstants.KEY_ROOM_ID];

      logger.log('🤝 [FileHandshake] Initiating file transfer');
      logger.log('📝 Transfer ID: $transferId');
      logger.log('👤 Chat ID: $chatId');
      logger.log('🏠 Room ID: $roomId');
      logger.log('📊 File Size: ${data[FileConstants.KEY_FILE_SIZE]}');
      logger.log('📦 Total Packets: ${data[FileConstants.KEY_TOTAL_PACKETS]}');

      final completer = Completer<bool>();
      _pendingTransfers[transferId] = completer;

      // Send the request directly
      FileJsonHelper.sendPacket(clientState.socket, clientState.serverAddress,
          clientState.serverPort, request);

      logger.log('📤 [FileHandshake] File transfer request sent');

      return completer.future.timeout(Duration(seconds: 30), onTimeout: () {
        logger.log('⏰ [FileHandshake] Transfer request timed out: $transferId');
        _pendingTransfers.remove(transferId);
        return false;
      });
    } catch (e) {
      logger.log('❌ [FileHandshake] Error initiating transfer: $e');
      return false;
    }
  }

  void handleResponse(Map<String, dynamic> response) {
    final transferId = response['data']['transferId'];
    logger
        .log('📥 [FileHandshake] Handling response for transfer: $transferId');

    final completer = _pendingTransfers[transferId];
    if (completer != null) {
      logger.log('✅ [FileHandshake] Transfer request completed: $transferId');
      completer.complete(response['status'] == 'success');
      _pendingTransfers.remove(transferId);
    } else {
      logger.log(
          '❌ [FileHandshake] No pending transfer found for ID: $transferId');
    }
  }
}
