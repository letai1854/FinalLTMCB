import 'package:finalltmcb/File/Core/file_handshake_manager.dart';

import 'base_handler.dart';

class ImageHandler extends BaseHandler {
  @override
  bool canHandle(String command) => command.startsWith('/image');

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
      fileType: 'image',
      totalPackages: totalPackages,
    );

    // Send request logic here
  }
}
