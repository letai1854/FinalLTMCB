import 'package:finalltmcb/Model/ChatMessage.dart';
import 'package:mime/mime.dart';

class MessageTypeHelper {
  static String determineMessageType(Map<String, dynamic> messageData) {
    if (messageData['file'] != null) {
      final fileData = messageData['file'];
      final mimeType = fileData['mimeType'] ?? '';

      if (mimeType.startsWith('image/')) {
        return 'image';
      } else if (mimeType.startsWith('video/')) {
        return 'video';
      } else if (mimeType.startsWith('audio/')) {
        return 'audio';
      } else {
        return 'file';
      }
    }

    return 'text';
  }

  static String getMessageDisplay(String sender, String type, String content) {
    switch (type) {
      case 'image':
        return '$sender đã gửi một hình ảnh';
      case 'video':
        return '$sender đã gửi một video';
      case 'audio':
        return '$sender đã gửi một ghi âm';
      case 'file':
        return '$sender đã gửi một tệp tin';
      default:
        return '$sender: $content';
    }
  }
}
