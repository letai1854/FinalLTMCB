import 'dart:io' as io;
import 'package:finalltmcb/File/Core/file_handshake_manager.dart';
import 'base_handler.dart';
import '../Models/file_constants.dart';

class FileHandler extends BaseHandler {
  @override
  bool canHandle(String command) => command.startsWith('/file');

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
    try {
      // Get file details
      final file = io.File(filePath);
      final fileExtension = filePath.split('.').last;

      // Calculate actual file details
      final actualSize = await file.length();
      final actualTotalPackages = (actualSize / (512 * 1024)).ceil();

      final request = createInitRequest(
        chatId: chatId,
        roomId: roomId,
        filePath: filePath,
        fileSize: actualSize,
        fileType: '$fileType.$fileExtension',
        totalPackages: actualTotalPackages,
      );

      print('File details calculated:');
      print('Path: $filePath');
      print('Extension: .$fileExtension');
      print('Size: $actualSize bytes');
      print('Packages: $actualTotalPackages');

      await handshakeManager?.initiateFileTransfer(request);
    } catch (e) {
      print('Error handling file: $e');
      throw Exception('Failed to process file: $e');
    }
  }
}
