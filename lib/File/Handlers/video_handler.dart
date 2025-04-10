import 'package:finalltmcb/File/Core/file_handshake_manager.dart';

import 'base_handler.dart';

class VideoHandler extends BaseHandler {
  @override
  bool canHandle(String command) => command.startsWith('/video');

  @override
  Future<void> handle({
    required String roomId,
    required String chatId,
    required String filePath,
    required int fileSize,
    required String fileType,
    required int totalPackages,
    required FileHandshakeManager? handshakeManager,
  }) async {
    final request = createInitRequest(
      chatId: chatId,
      roomId: roomId,
      filePath: filePath,
      fileSize: fileSize,
      fileType: 'video',
      totalPackages: totalPackages,
    );

    // Send request logic here
  }
}
