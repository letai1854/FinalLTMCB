import 'dart:convert';
import 'dart:typed_data';

class VideoFileMessage {
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String base64Data;
  final String localPath;
  final int duration;
  final String? thumbnail;

  VideoFileMessage({
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.base64Data,
    required this.localPath,
    this.duration = 0,
    this.thumbnail,
  });

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'mimeType': mimeType,
        'fileSize': fileSize,
        'base64Data': base64Data,
        'localPath': localPath,
        'duration': duration,
        'thumbnail': thumbnail,
      };

  factory VideoFileMessage.fromJson(Map<String, dynamic> json) {
    return VideoFileMessage(
      fileName: json['fileName'],
      mimeType: json['mimeType'],
      fileSize: json['fileSize'],
      base64Data: json['base64Data'],
      localPath: json['localPath'],
      duration: json['duration'] ?? 0,
      thumbnail: json['thumbnail'],
    );
  }

  String get readableSize {
    final kb = 1024;
    final mb = kb * 1024;
    if (fileSize >= mb) {
      return '${(fileSize / mb).toStringAsFixed(1)} MB';
    }
    if (fileSize >= kb) {
      return '${(fileSize / kb).toStringAsFixed(1)} KB';
    }
    return '$fileSize B';
  }

  Uint8List getVideoBytes() => base64Decode(base64Data);
}
