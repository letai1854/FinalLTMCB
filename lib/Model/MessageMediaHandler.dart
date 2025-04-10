import 'dart:convert';
import 'dart:io';
import 'package:finalltmcb/Widget/FilePickerUtil.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:finalltmcb/Model/ChatMessage.dart';
import 'package:finalltmcb/File/Models/MessageContentParser.dart';
import 'package:finalltmcb/Model/FileTransferQueue.dart';
import 'package:finalltmcb/File/Models/file_constants.dart';
import 'package:finalltmcb/Model/VideoFileMessage.dart';

class MessageMediaHandler {
  final Function(Function()) setState;

  MessageMediaHandler(this.setState);

  void handleFileMessage(ChatMessage message, MediaInfo mediaInfo) {
    final file = File(mediaInfo.filePath);
    if (!file.existsSync()) {
      _addToDownloadQueue(
        mediaInfo.chatId,
        mediaInfo.roomId,
        mediaInfo.filePath,
        'file',
      );
      return;
    }

    final newMessage = ChatMessage(
        text: message.text,
        isMe: message.isMe,
        timestamp: message.timestamp,
        name: message.name,
        file: FileMessage(
          fileName: path.basename(mediaInfo.filePath),
          mimeType:
              lookupMimeType(mediaInfo.filePath) ?? 'application/octet-stream',
          fileSize: file.lengthSync(),
          filePath: mediaInfo.filePath,
          totalPackages: 0,
          fileType: 'file',
        ));

    setState(() {
      message = newMessage;
    });
  }

  void handleMediaMessage(ChatMessage message, MediaInfo mediaInfo) {
    final file = File(mediaInfo.filePath);
    if (!file.existsSync()) {
      _addToDownloadQueue(
        mediaInfo.chatId,
        mediaInfo.roomId,
        mediaInfo.filePath,
        mediaInfo.fileType,
      );
      return;
    }

    ChatMessage newMessage;
    switch (mediaInfo.fileType) {
      case 'image':
        newMessage = ChatMessage(
          text: message.text,
          isMe: message.isMe,
          timestamp: message.timestamp,
          name: message.name,
          image: base64Encode(file.readAsBytesSync()),
          mimeType: lookupMimeType(mediaInfo.filePath),
        );
        break;

      case 'video':
        newMessage = ChatMessage(
          text: message.text,
          isMe: message.isMe,
          timestamp: message.timestamp,
          name: message.name,
          video: VideoFileMessage(
            fileName: path.basename(mediaInfo.filePath),
            mimeType: lookupMimeType(mediaInfo.filePath) ?? 'video/mp4',
            fileSize: file.lengthSync(),
            base64Data: '',
            localPath: mediaInfo.filePath,
          ),
        );
        break;

      case 'audio':
        newMessage = ChatMessage(
          text: message.text,
          isMe: message.isMe,
          timestamp: message.timestamp,
          name: message.name,
          audio: mediaInfo.filePath,
          isAudioPath: true,
        );
        break;

      default:
        return;
    }

    setState(() {
      message = newMessage;
    });
  }

  void _addToDownloadQueue(
    String chatId,
    String roomId,
    String filePath,
    String fileType,
  ) {
    final item = FileTransferItem(
      status: FileConstants.Action_Status_File_Download,
      currentChatId: chatId,
      userId: roomId,
      filePath: filePath,
      actualFileSize: 0,
      fileType: fileType,
      actualTotalPackages: 0,
    );

    FileTransferQueue.instance.addToQueue(item);
  }
}
