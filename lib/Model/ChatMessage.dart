import 'dart:convert';
import 'dart:typed_data';
import 'package:finalltmcb/Model/AudioMessage.dart';
import 'package:finalltmcb/Model/ImageMessage.dart';
import 'package:finalltmcb/Model/MessageData.dart'; // Import MessageData
import 'package:finalltmcb/Widget/FilePickerUtil.dart';
import 'package:finalltmcb/Model/VideoFileMessage.dart'; // Thêm import này

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String? image;
  final String? mimeType;
  final FileMessage? file;
  final String? audio;
  final bool isAudioPath;
  final VideoFileMessage? video; // Thay đổi chính
  final bool isVideoLoading; // Flag for video loading state
  final bool isVideoUploading; // Flag for video uploading state
  final MessageData? messageData;
  final String? name;
  const ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.image,
    this.mimeType = null,
    this.file,
    this.audio,
    this.isAudioPath = false,
    this.video, // Cập nhật constructor
    this.isVideoLoading = false,
    this.isVideoUploading = false,
    this.messageData,
    this.name,
  });

  // Helper method to determine if this is an audio message
  bool get isAudioMessage => audio != null && audio!.isNotEmpty;

  // Helper method to determine if this is an image message
  bool get isImageMessage => image != null && image!.isNotEmpty;

  // Helper method to determine if this is a file message
  bool get isFileMessage => file != null;

  // Helper method to determine if this is a video message
  bool get isVideoMessage => video != null;

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isMe': isMe,
      'timestamp': timestamp.toIso8601String(),
      'image': image,
      'mimeType': mimeType,
      'file': file?.toJson(),
      'audio': audio,
      'isAudioPath': isAudioPath,
      'video': video?.toJson(), // Cập nhật toJson
      'isVideoLoading': isVideoLoading,
      'isVideoUploading': isVideoUploading,
      'messageData': messageData?.toJson(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isMe: json['isMe'],
      timestamp: DateTime.parse(json['timestamp']),
      image: json['image'],
      mimeType: json['mimeType'],
      file: json['file'] != null ? FileMessage.fromJson(json['file']) : null,
      audio: json['audio'],
      isAudioPath: json['isAudioPath'],
      video: json['video'] != null // Cập nhật fromJson
          ? VideoFileMessage.fromJson(json['video'])
          : null,
      isVideoLoading: json['isVideoLoading'] ?? false,
      isVideoUploading: json['isVideoUploading'] ?? false,
      messageData: json['messageData'] != null
          ? MessageData.fromJson(json['messageData'])
          : null,
    );
  }
}
