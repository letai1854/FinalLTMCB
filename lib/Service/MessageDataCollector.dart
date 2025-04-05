import 'package:finalltmcb/Model/MessageData.dart';
import 'package:finalltmcb/Model/ImageMessage.dart';
import 'package:finalltmcb/Model/AudioMessage.dart';
import 'package:finalltmcb/Model/VideoFileMessage.dart';
import 'package:finalltmcb/Widget/FilePickerUtil.dart';
import 'dart:convert';
import 'dart:typed_data';

class MessageDataCollector {
  static Future<MessageData> collectTextAndImageData({
    String? text,
    List<ImageMessage>? images,
    required DateTime timestamp,
  }) async {
    print('\n====== Text/Image Message Collection ======');
    print('Time: $timestamp');

    final messageData = MessageData(
      text: text,
      images: images ?? [],
      audios: [],
      files: [],
      video: null,
      timestamp: timestamp,
    );

    logMessageContent(messageData);
    return messageData;
  }

  static Future<MessageData> collectMediaData({
    FileMessage? file,
    VideoFileMessage? video,
    String? audioBase64,
    required DateTime timestamp,
  }) async {
    print('\n====== Media Message Collection ======');
    print('Time: $timestamp');

    MessageData messageData;

    if (file != null) {
      print('\nProcessing File:');
      print('Name: ${file.fileName}');
      print('Size: ${file.readableSize}');
      print('MIME: ${file.mimeType}');

      messageData = MessageData(
        text: null,
        images: [],
        audios: [],
        files: [file],
        video: null,
        timestamp: timestamp,
      );
    } else if (video != null) {
      print('\nProcessing Video:');
      print('Name: ${video.fileName}');
      print('Size: ${video.readableSize}');
      print('Duration: ${video.duration}ms');

      messageData = MessageData(
        text: null,
        images: [],
        audios: [],
        files: [],
        video: video,
        timestamp: timestamp,
      );
    } else if (audioBase64 != null) {
      print('\nProcessing Audio:');
      print('Size: ${base64Decode(audioBase64).length} bytes');

      final audioData = AudioData(
        base64Data: audioBase64,
        duration: 0,
        mimeType: 'audio/mp4',
        size: base64Decode(audioBase64).length,
      );

      messageData = MessageData(
        text: null,
        images: [],
        audios: [audioData],
        files: [],
        video: null,
        timestamp: timestamp,
      );
    } else {
      print('Warning: No media content found');
      messageData = MessageData(
        text: null,
        images: [],
        audios: [],
        files: [],
        video: null,
        timestamp: timestamp,
      );
    }

    logMessageContent(messageData);
    return messageData;
  }

  static Future<MessageData> collectAudioData({
    required AudioData audioData,
    required DateTime timestamp,
  }) async {
    print('\n====== Audio Message Collection ======');
    print('Time: $timestamp');

    final messageData = MessageData(
      text: null,
      images: [],
      audios: [audioData],
      files: [],
      video: null,
      timestamp: timestamp,
    );

    logMessageContent(messageData);
    return messageData;
  }

  static void logMessageContent(MessageData data) {
    print('\n--- Message Content Details ---');
    print('Timestamp: ${data.timestamp}');

    // Text
    print('Text: ${data.text ?? "NULL"}');

    // Images
    if (data.images.isNotEmpty) {
      print('\nImages:');
      for (var i = 0; i < data.images.length; i++) {
        print('Image $i:');
        print('- Size: ${data.images[i].size} bytes');
        print('- Type: ${data.images[i].mimeType}');
      }
    } else {
      print('Images: NULL');
    }

    // Audio
    if (data.audios.isNotEmpty) {
      print('\nAudio:');
      for (var i = 0; i < data.audios.length; i++) {
        print('Audio $i:');
        print('- Size: ${data.audios[i].size} bytes');
        print('- Duration: ${data.audios[i].duration}ms');
      }
    } else {
      print('Audio: NULL');
    }

    // Files
    if (data.files.isNotEmpty) {
      print('\nFiles:');
      for (var i = 0; i < data.files.length; i++) {
        print('File $i:');
        print('- Name: ${data.files[i].fileName}');
        print('- Size: ${data.files[i].readableSize}');
      }
    } else {
      print('Files: NULL');
    }

    // Video
    if (data.video != null) {
      print('\nVideo:');
      print('- Name: ${data.video!.fileName}');
      print('- Size: ${data.video!.readableSize}');
      print('- Duration: ${data.video!.duration}ms');
    } else {
      print('Video: NULL');
    }

    print('\nTotal payload size: ${jsonEncode(data.toJson()).length} bytes');
    print('--------------------------------\n');
  }
}
