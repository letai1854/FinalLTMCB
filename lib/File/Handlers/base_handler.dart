import 'dart:io';
import 'package:finalltmcb/File/Core/file_handshake_manager.dart';

import '../Models/file_constants.dart';
import '../Core/file_json_helper.dart';

abstract class BaseHandler {
  Future<void> handle({
    required String roomId,
    required String chatId,
    required String filePath,
    required int fileSize,
    required String fileType,
    required int totalPackages,
    required FileHandshakeManager? handshakeManager,
  });

  bool canHandle(String command);

  Map<String, dynamic> createInitRequest({
    required String chatId,
    required String roomId,
    required String filePath,
    required int fileSize,
    required String fileType,
    required int totalPackages,
  }) {
    return {
      'action': FileConstants.ACTION_FILE_SEND_INIT,
      'data': {
        FileConstants.KEY_CHAT_ID: chatId,
        FileConstants.KEY_ROOM_ID: roomId,
        FileConstants.KEY_FILE_PATH: filePath,
        FileConstants.KEY_FILE_SIZE: fileSize,
        FileConstants.KEY_FILE_TYPE: fileType,
        FileConstants.KEY_TOTAL_PACKETS: totalPackages,
      }
    };
  }

  Future<Map<String, dynamic>> prepareMetadata(String filePath) async {
    final file = File(filePath);
    final stats = await file.stat();

    return {
      'fileName': file.path.split(Platform.pathSeparator).last,
      'size': stats.size,
      'modified': stats.modified.toIso8601String(),
    };
  }

  Future<List<int>> readChunk(String filePath, int start, int chunkSize) async {
    final file = File(filePath);
    final raf = await file.open();
    try {
      await raf.setPosition(start);
      return await raf.read(chunkSize);
    } finally {
      await raf.close();
    }
  }

  // Calculate file size from path
  Future<int> calculateFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }
      return await file.length();
    } catch (e) {
      print('Error calculating file size: $e');
      return 0;
    }
  }

  // Calculate total packages based on file size
  int calculateTotalPackages(int fileSize) {
    const int PACKAGE_SIZE = 512 * 1024; // 512KB per package
    return (fileSize / PACKAGE_SIZE).ceil();
  }

  // Combined method to get both file size and total packages
  Future<Map<String, int>> getFileDetails(String filePath) async {
    final fileSize = await calculateFileSize(filePath);
    final totalPackages = calculateTotalPackages(fileSize);
    return {
      'fileSize': fileSize,
      'totalPackages': totalPackages,
    };
  }
}
