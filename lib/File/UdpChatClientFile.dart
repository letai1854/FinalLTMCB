import 'dart:developer' as logger;
import 'Core/file_command_processor.dart';
import 'Core/file_handshake_manager.dart';
import 'Core/file_message_listener.dart';
import 'ClientStateForFile.dart';

class UdpChatClientFile {
  final ClientStateForFile clientState;
  final FileHandshakeManager handshakeManager;
  final FileCommandProcessor commandProcessor;
  final FileMessageListener messageListener;

  UdpChatClientFile._internal(this.clientState, this.handshakeManager,
      this.commandProcessor, this.messageListener);

  static Future<UdpChatClientFile> create(
      String host, int port, int portFile) async {
    logger.log('⚡ [FileClient] Initializing UDP File Client on $host:$port');

    try {
      final clientState = await ClientStateForFile.create(host, port, portFile);
      logger.log(
          '🔌 [FileClient] Client state created. Socket bound to port ${clientState.socket.port}');

      // Verify server address and port
      if (clientState.serverAddress.address == '0.0.0.0') {
        throw Exception(
            'Invalid server address: ${clientState.serverAddress.address}');
      }

      logger.log(
          '🌐 Server address: ${clientState.serverAddress.address}:${clientState.serverPort}');

      final handshakeManager = FileHandshakeManager(clientState);
      final commandProcessor =
          FileCommandProcessor(clientState, handshakeManager);
      final messageListener =
          FileMessageListener(clientState, handshakeManager);

      return UdpChatClientFile._internal(
          clientState, handshakeManager, commandProcessor, messageListener);
    } catch (e) {
      logger.log('❌ [FileClient] Error creating UDP File Client: $e');
      rethrow;
    }
  }

  Future<bool> start() async {
    try {
      logger.log('🚀 [FileClient] Starting UDP File Client services');
      messageListener.startListening();
      logger.log('👂 [FileClient] Message listener started');
      return true;
    } catch (e) {
      logger.log('❌ [FileClient] Error starting client: $e');
      return false;
    }
  }

  void close() {
    logger.log('🔄 [FileClient] Beginning shutdown sequence');
    clientState.close();
    logger.log('🔌 [FileClient] Client state closed');
    messageListener.stopListening();
    logger.log('👋 [FileClient] Message listener stopped');
    logger.log('✅ [FileClient] UDP File Client shutdown complete');
  }
}
