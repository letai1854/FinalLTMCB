import 'package:finalltmcb/File/Core/file_handshake_manager.dart';

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
}
