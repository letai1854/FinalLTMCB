import 'dart:async';
import 'dart:developer' as logger;

import 'package:finalltmcb/Controllers/MessageController.dart';

class FileTransferState {
  static final FileTransferState _instance = FileTransferState._internal();
  static FileTransferState get instance => _instance;
  bool isTransferring = false;
  FileTransferState._internal();
}

class FileTransferItem {
  final String currentChatId;
  final String userId;
  final String filePath;
  final int actualFileSize;
  final String fileType;
  final int actualTotalPackages;

  FileTransferItem({
    required this.currentChatId,
    required this.userId,
    required this.filePath,
    required this.actualFileSize,
    required this.fileType,
    required this.actualTotalPackages,
  });
}

class FileTransferQueue {
  static final FileTransferQueue _instance = FileTransferQueue._internal();
  static FileTransferQueue get instance => _instance;
  final List<FileTransferItem> _queue = [];
  Timer? _processTimer;
  final FileTransferState _state = FileTransferState.instance;

  FileTransferQueue._internal() {
    _startQueueProcessor();
  }

  void _startQueueProcessor() {
    _processTimer?.cancel();
    _processTimer = Timer.periodic(Duration(milliseconds: 500), (_) {
      _processNextItem();
    });
  }

  Future<void> _processNextItem() async {
    if (_queue.isEmpty || _state.isTransferring) return;

    try {
      final item = _queue.first;
      _state.isTransferring = true;

      // Process the item
      await MessageController().SendFileMessage(
          item.currentChatId,
          item.userId,
          item.filePath,
          item.actualFileSize,
          item.fileType,
          item.actualTotalPackages);
    } catch (e) {
      logger.log('Error processing file transfer: $e');
      _state.isTransferring = false;
    }
  }

  void addToQueue(FileTransferItem item) {
    _queue.add(item);
    logger.log('Added item to queue. Queue size: ${_queue.length}');
  }

  void removeFirst() {
    if (_queue.isNotEmpty) {
      _queue.removeAt(0);
      _state.isTransferring = false;
      logger.log('Removed item from queue. Queue size: ${_queue.length}');
    }
  }

  bool get isEmpty => _queue.isEmpty;

  void dispose() {
    _processTimer?.cancel();
  }
}
