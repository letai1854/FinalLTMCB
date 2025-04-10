import 'dart:async';
import 'dart:typed_data';
import 'dart:developer' as logger;
import 'dart:io';
import 'dart:convert';
import 'package:flutter/animation.dart';
import 'package:media_kit/generated/libmpv/bindings.dart';
import 'dart:io' as io;
import '../ClientStateForFile.dart';
import '../Models/file_constants.dart';
import 'file_json_helper.dart';
import 'package:path/path.dart' as path;

class FileHandshakeManager {
  // Match Java's actual chunk size: 32 KB
  static const int DATA_CHUNK_SIZE = 1024 * 32;
  static const int MAX_RETRIES = 3;
  static const int RETRY_DELAY_MS = 1000;

  final ClientStateForFile clientStateFile;
  final Map<String, Completer<bool>> _pendingTransfers = {};

  FileHandshakeManager(this.clientStateFile);

  Future<bool> SendPackageTransfer(Map<String, dynamic> request) async {
    try {
      final data = request['data'];
      final transferId = DateTime.now().millisecondsSinceEpoch.toString();
      final chatId = data[FileConstants.KEY_CHAT_ID];
      final roomId = data[FileConstants.KEY_ROOM_ID];
      final filePath = data[FileConstants.KEY_FILE_PATH];
      final fileSize = data[FileConstants.KEY_FILE_SIZE];

      logger.log('🤝 [FileHandshake] Starting file transfer');

      // Send first data chunk
      try {
        final file = File(filePath);
        final raf = await file.open();
        try {
          // Read first chunk from position 0
          const CHUNK_SIZE = DATA_CHUNK_SIZE; // Use the class constant (32KB)
          final dataBuffer = Uint8List(CHUNK_SIZE);
          await raf.setPosition(0); // Ensure we start from beginning
          // Use readInto to read into the buffer and get the number of bytes read
          final bytesRead = await raf.readInto(dataBuffer);

          // readInto returns the number of bytes read (0 for EOF)
          if (bytesRead > 0) {
            // Create actual data array of exact size and encode to base64
            final actualData = dataBuffer.sublist(0, bytesRead);
            final base64Data = base64Encode(actualData);

            // Create data packet like Java code
            final dataPacket = {
              'action': 'file_send_data',
              'data': {
                'chat_id': chatId,
                'room_id': roomId,
                'file_path': filePath,
                'sequence_number': 1,
                'chunk_size': bytesRead,
                'file_data': base64Data
              }
            };

            // Send with retry logic
            var packetSent = false;
            var retries = 0;
            const MAX_RETRIES = 3;
            const RETRY_DELAY_MS = 1000;

            logger.log('Server address: ${clientStateFile.serverAddress}');
            logger.log('Server port: ${clientStateFile.serverPort}');
            logger.log('Chunk size: $bytesRead');
            print('Data packet: $dataPacket');
            while (!packetSent && retries < MAX_RETRIES) {
              try {
                FileJsonHelper.sendPacket(
                    clientStateFile.socket,
                    clientStateFile.serverAddress,
                    clientStateFile.serverPort,
                    dataPacket);
                packetSent = true;
                logger
                    .log('📤 First chunk sent successfully: $bytesRead bytes');
              } catch (e) {
                retries++;
                if (retries < MAX_RETRIES) {
                  logger.log('⚠️ Error sending first chunk, retrying...');
                  await Future.delayed(Duration(milliseconds: RETRY_DELAY_MS));
                } else {
                  throw Exception(
                      'Failed to send first chunk after $MAX_RETRIES attempts');
                }
              }
            }
          }
        } finally {
          await raf.close();
        }
      } catch (e) {
        logger.log('❌ Error sending first chunk: $e');
        throw e;
      }

      // Send initial request
      logger.log('Server address: ${clientStateFile.serverAddress}');
      logger.log('Server port: ${clientStateFile.serverPort}');
      logger.log('File path: $filePath');
      logger.log('File size: $fileSize');

      // Send initial request
      final completer = Completer<bool>();
      _pendingTransfers[transferId] = completer;

      return completer.future.timeout(Duration(seconds: 30), onTimeout: () {
        logger.log('⏰ Transfer request timed out: $transferId');
        _pendingTransfers.remove(transferId);
        return false;
      });
    } catch (e) {
      logger.log('❌ Error in file transfer: $e');
      return false;
    }
  }

  Future<void> sendRemainingChunks(Map<String, dynamic> request) async {
    try {
      final data = request['data'];
      final chatId = data[FileConstants.KEY_CHAT_ID];
      final roomId = data[FileConstants.KEY_ROOM_ID];
      final filePath = data[FileConstants.KEY_FILE_PATH];
      var sequenceNumber = data['sequence_number'] as int;

      final file = File(filePath);
      final raf = await file.open();
      var totalBytesSent = DATA_CHUNK_SIZE; // Account for first chunk
      final normalizedPath = path.normalize(filePath);
      final size_t = io.File(normalizedPath);
      final stats = await size_t.stat();
      final actualSize = stats.size;
      final totalPackets = (actualSize / DATA_CHUNK_SIZE).ceil();

      try {
        if (sequenceNumber >= totalPackets) {
          print(
              "---------------------file transfer completed---------------------");
          final dataPacket = {
            'action': 'file_send_fin',
            'data': {
              'chat_id': chatId,
              'room_id': roomId,
              'file_path': filePath,
            }
          };
          await FileJsonHelper.sendPacket(
              clientStateFile.socket,
              clientStateFile.serverAddress,
              clientStateFile.serverPort,
              dataPacket);
          return; // Reset sequence number for new transfer
        }
        if (sequenceNumber < totalPackets) {
          sequenceNumber++;
          // Calculate correct file position based on sequence number
          final position = (sequenceNumber - 1) * DATA_CHUNK_SIZE;
          await raf.setPosition(position);

          final dataBuffer = Uint8List(DATA_CHUNK_SIZE);
          final bytesRead = await raf.readInto(dataBuffer);

          final actualData = dataBuffer.sublist(0, bytesRead);
          final base64Data = base64Encode(actualData);

          final dataPacket = {
            'action': 'file_send_data',
            'data': {
              'chat_id': chatId,
              'room_id': roomId,
              'file_path': filePath,
              'sequence_number': sequenceNumber,
              'chunk_size': bytesRead,
              'file_data': base64Data
            }
          };

          var packetSent = false;
          var retries = 0;

          while (!packetSent && retries < MAX_RETRIES) {
            try {
              await FileJsonHelper.sendPacket(
                  clientStateFile.socket,
                  clientStateFile.serverAddress,
                  clientStateFile.serverPort,
                  dataPacket);
              packetSent = true;
              totalBytesSent += bytesRead;

              if (sequenceNumber % 10 == 0 || sequenceNumber == totalPackets) {
                final progress =
                    (totalBytesSent / actualSize * 100).toStringAsFixed(1);
                logger.log(
                    '📤 Progress: $progress% ($sequenceNumber/$totalPackets packets sent)');
              }
            } catch (e) {
              retries++;
              if (retries < MAX_RETRIES) {
                logger
                    .log('⚠️ Error sending chunk $sequenceNumber, retrying...');
                await Future.delayed(Duration(milliseconds: RETRY_DELAY_MS));
              } else {
                throw Exception(
                    'Failed to send chunk $sequenceNumber after $MAX_RETRIES attempts');
              }
            }
          }

          await Future.delayed(Duration(milliseconds: 5)); // Basic rate control
        }

        logger.log('✅ All remaining chunks sent successfully');
      } finally {
        await raf.close();
      }
    } catch (e) {
      logger.log('❌ Error sending remaining chunks: $e');
      throw e;
    }
  }

  void _handleFileData(Map<String, dynamic> response) {
    if (response['status'] == 'success') {
      SendPackageTransfer(response);
    }
  }

  void handleResponse(Map<String, dynamic> response) {
    print(response);
    if (response['status'] == 'success') {
      _handleFileData(response);
    }
  }

  Future<void> InitFileTranfer(Map<String, dynamic> request) async {
    FileJsonHelper.sendPacket(clientStateFile.socket,
        clientStateFile.serverAddress, clientStateFile.serverPort, request);
  }

  Future<void> InitFileDownload(Map<String, dynamic> request) async {
    try {
      await FileJsonHelper.sendPacket(clientStateFile.socket,
          clientStateFile.serverAddress, clientStateFile.serverPort, request);
      print('File download request sent successfully');
    } catch (e) {
      print('Error initiating file download: $e');
      throw Exception('Failed to initiate file download: $e');
    }
  }
}
