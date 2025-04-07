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

  static Future<UdpChatClientFile> create(String host, int port) async {
    logger.log('⚡ [FileClient] Initializing UDP File Client on $host:$port');

    final clientState = await ClientStateForFile.create(host, port);
    logger.log(
        '🔌 [FileClient] Client state created. Socket bound to port ${clientState.socket.port}');

    final handshakeManager = FileHandshakeManager(clientState);
    logger.log('🤝 [FileClient] Handshake manager initialized');

    final commandProcessor =
        FileCommandProcessor(clientState, handshakeManager);
    logger.log('⌨️ [FileClient] Command processor initialized');

    final messageListener = FileMessageListener(clientState, handshakeManager);
    logger.log('👂 [FileClient] Message listener initialized');

    logger.log('✅ [FileClient] UDP File Client initialization complete');

    return UdpChatClientFile._internal(
        clientState, handshakeManager, commandProcessor, messageListener);
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
