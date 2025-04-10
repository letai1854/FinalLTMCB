import 'dart:io' as io;
import 'package:finalltmcb/File/Core/file_handshake_manager.dart';
import 'base_handler.dart';
import '../Models/file_constants.dart';
import 'package:path/path.dart' as path;

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
      // Validate and normalize file path
      final normalizedPath = path.normalize(filePath);
      final file = io.File(normalizedPath);

      // Check if file exists
      if (!await file.exists()) {
        throw Exception('File not found at path: $normalizedPath');
      }

      // Get file extension safely
      String fileExtension = path.extension(normalizedPath);
      if (fileExtension.startsWith('.')) {
        fileExtension = fileExtension.substring(1);
      }
      if (fileExtension.isEmpty) {
        fileExtension = 'unknown';
      }

      // Get file stats
      final stats = await file.stat();
      final actualSize = stats.size;
      final actualTotalPackages = (actualSize / (1024 * 32)).ceil();

      print('File validation passed:');
      print('Original path: $filePath');
      print('Normalized path: $normalizedPath');
      print('Extension: $fileExtension');
      print('Size: $actualSize bytes');
      print('Total packages: $actualTotalPackages');

      final request = createInitRequest(
        chatId: chatId,
        roomId: roomId,
        filePath: filePath,
        fileSize: actualSize,
        fileType: fileType,
        totalPackages: actualTotalPackages,
      );

      await handshakeManager?.InitFileTranfer(request);
    } catch (e) {
      print('Error handling file: $e');
      final errorMessage =
          'Failed to process file: ${e.toString().split('\n')[0]}';
      throw Exception(errorMessage);
    }
  }
}
