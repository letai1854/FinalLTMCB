import 'dart:convert';
import 'dart:typed_data';
import 'package:finalltmcb/Model/AudioMessage.dart';
import 'package:finalltmcb/Model/ImageMessage.dart';
import 'package:finalltmcb/Widget/FilePickerUtil.dart';
import 'package:finalltmcb/Model/VideoFileMessage.dart';

class MessageData {
  final String? text;
  final List<ImageMessage> images;
  final List<AudioData> audios; // Add audio support
  final List<FileMessage> files; // Add file support
  final VideoFileMessage? video;
  final DateTime timestamp;

  MessageData({
    this.text,
    List<ImageMessage>? images,
    List<AudioData>? audios,
    List<FileMessage>? files,
    this.video,
    required this.timestamp,
  })  : images = images ?? [],
        audios = audios ?? [],
        files = files ?? [];

  Map<String, dynamic> toJson() => {
        'text': text,
        'images': images.map((img) => img.toJson()).toList(),
        'audios': audios.map((audio) => audio.toJson()).toList(),
        'files': files.map((file) => file.toJson()).toList(),
        'video': video?.toJson(),
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
      video: json['video'] != null
          ? VideoFileMessage.fromJson(json['video'])
          : null,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
