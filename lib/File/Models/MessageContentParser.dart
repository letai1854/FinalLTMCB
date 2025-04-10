class MessageContentParser {
  final String content;

  MessageContentParser(this.content);

  bool get isMediaMessage {
    final fileType = _extractFileType();
    return ['image', 'video', 'audio', 'file'].contains(fileType);
  }

  String _extractFileType() {
    final match = RegExp(r'file_type\s+(\S+)').firstMatch(content);
    return match?.group(1)?.trim() ?? '';
  }

  String extractFilePath() {
    final match = RegExp(r'file_path\s+(.*?)\s+(?:chat_id|room_id|file_type)')
        .firstMatch(content);
    return match?.group(1)?.trim() ?? '';
  }

  MediaInfo getMediaInfo() {
    return MediaInfo(
        filePath: extractFilePath(),
        fileType: _extractFileType(),
        chatId: _extractField('chat_id'),
        roomId: _extractField('room_id'));
  }

  String _extractField(String fieldName) {
    final match = RegExp('$fieldName\\s+(\\S+)').firstMatch(content);
    return match?.group(1)?.trim() ?? '';
  }
}

class MediaInfo {
  final String filePath;
  final String fileType;
  final String chatId;
  final String roomId;

  MediaInfo(
      {required this.filePath,
      required this.fileType,
      required this.chatId,
      required this.roomId});
}
