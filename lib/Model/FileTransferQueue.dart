import 'dart:async';
import 'dart:developer' as logger;

import 'package:finalltmcb/Controllers/MessageController.dart';
import 'package:finalltmcb/File/Models/file_constants.dart';

class FileTransferState {
  static final FileTransferState _instance = FileTransferState._internal();
  static FileTransferState get instance => _instance;
  bool isTransferring = false;
  FileTransferState._internal();
}

class FileTransferItem {
  final String status;
  final String currentChatId;
  final String userId;
  final String filePath;
  final int actualFileSize;
  final String fileType;
  final int actualTotalPackages;

  FileTransferItem({
    required this.status,
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
  bool isFileInQueue(String filePath) {
    return _queue.any((item) => item.filePath == filePath);
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
      print(item);
      _state.isTransferring = true;

      logger.log('Processing queue item:', name: 'FileTransferQueue');
      logger.log('Status: ${item.status}', name: 'FileTransferQueue');
      logger.log('File: ${item.filePath}', name: 'FileTransferQueue');

      // Add retry mechanism
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          // Process the item
          if (item.status == FileConstants.Action_Status_File_Send) {
            await MessageController().SendFileMessage(
                item.status,
                item.currentChatId,
                item.userId,
                item.filePath,
                item.actualFileSize,
                item.fileType,
                item.actualTotalPackages);
            break; // Success, exit retry loop
          } else if (item.status == FileConstants.Action_Status_File_Download) {
            await MessageController.instance.DownloadFileMessage(
                item.currentChatId, item.userId, item.filePath, item.fileType);
            break; // Success, exit retry loop
          }
        } catch (e) {
          retryCount++;
          logger.log('Transfer attempt $retryCount failed: $e',
              name: 'FileTransferQueue');
          if (retryCount >= maxRetries) {
            throw e; // Re-throw if max retries reached
          }
          await Future.delayed(
              Duration(seconds: 2 * retryCount)); // Exponential backoff
        }
      }
    } catch (e) {
      logger.log('Error processing file transfer: $e',
          name: 'FileTransferQueue');
      _state.isTransferring = false;
      removeFirst(); // Remove failed item and continue
    }
  }

  void addToQueue(FileTransferItem item) {
    // Check if file is already in queue to prevent duplicates
    if (_queue.any((queueItem) => queueItem.filePath == item.filePath)) {
      logger.log('⚠️ File ${item.filePath} already in queue, skipping duplicate', name: 'FileTransferQueue');
      return;
    }
    
    _queue.add(item);
    logger.log('Added item to queue. Queue size: ${_queue.length}');
  }

  void removeFirst() {
    if (_queue.isNotEmpty) {
      final removedItem = _queue.removeAt(0);
      _state.isTransferring = false;

      logger.log('=== Queue Status Update ===', name: 'FileTransferQueue');
      logger.log('Removed item: ${removedItem.filePath}',
          name: 'FileTransferQueue');
      logger.log('Remaining items: ${_queue.length}',
          name: 'FileTransferQueue');

      // Report queue status
      if (_queue.isNotEmpty) {
        logger.log('Next item: ${_queue.first.filePath}',
            name: 'FileTransferQueue');
      }

      _notifyQueueUpdate();
    }
  }

  // Add queue update notification
  final StreamController<int> _queueUpdateController =
      StreamController<int>.broadcast();
  Stream<int> get queueUpdates => _queueUpdateController.stream;

  void _notifyQueueUpdate() {
    _queueUpdateController.add(_queue.length);
  }

  bool get isEmpty => _queue.isEmpty;

  void dispose() {
    _processTimer?.cancel();
    _queueUpdateController.close();
  }
}
