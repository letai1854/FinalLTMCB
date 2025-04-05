import 'dart:convert';
import 'dart:typed_data';
import 'package:finalltmcb/Model/AudioMessage.dart';
import 'package:finalltmcb/Model/ImageMessage.dart';
import 'package:finalltmcb/Widget/FilePickerUtil.dart';

class MessageData {
  final String? text;
  final List<ImageMessage> images;
  final List<AudioData> audios; // Add audio support
  final List<FileMessage> files; // Add file support
  final Uint8List? videoBytes; // Add videoBytes support
  final DateTime timestamp;

  MessageData({
    this.text,
    List<ImageMessage>? images,
    List<AudioData>? audios,
    List<FileMessage>? files,
    this.videoBytes, // Add videoBytes to constructor
    required this.timestamp,
  })  : images = images ?? [],
        audios = audios ?? [],
        files = files ?? [];

  Map<String, dynamic> toJson() => {
        'text': text,
        'images': images.map((img) => img.toJson()).toList(),
        'audios': audios.map((audio) => audio.toJson()).toList(),
        'files': files.map((file) => file.toJson()).toList(),
        'videoBytes': videoBytes != null
            ? base64Encode(videoBytes!.cast<int>())
            : null, // Encode videoBytes to base64
        'timestamp': timestamp.toIso8601String(),
      };

  factory MessageData.fromJson(Map<String, dynamic> json) {
    return MessageData(
      text: json['text'],
      images: (json['images'] as List?)
              ?.map((img) => ImageMessage.fromJson(img))
              .toList() ??
          [],
      audios: (json['audios'] as List?)
              ?.map((audio) => AudioData.fromJson(audio))
              .toList() ??
          [],
      files: (json['files'] as List?)
              ?.map((file) => FileMessage.fromJson(file))
              .toList() ??
          [],
      videoBytes: json['videoBytes'] != null
          ? base64Decode(json['videoBytes']).cast<int>() as Uint8List
          : null, // Decode base64 to Uint8List
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
