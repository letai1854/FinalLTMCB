import 'package:flutter/foundation.dart';

class MessageNotifier {
  // Notifier cho tin nhắn mới
  static final ValueNotifier<Map<String, dynamic>?> messageNotifier =
      ValueNotifier(null);

  // Notifier cho phòng chat mới
  static final ValueNotifier<Map<String, dynamic>?> messageNotifierRoom =
      ValueNotifier(null);

  static final ValueNotifier<List<String>> messageNotifierListUser =
      ValueNotifier([]);
  static final ValueNotifier<Map<String, dynamic>?> messageNotifierRecieveFile =
      ValueNotifier(null);
  // Cập nhật khi có tin nhắn mới
  static void updateMessage(Map<String, dynamic> messageData) {
    messageNotifier.value = messageData;
  }

  // Cập nhật khi có phòng chat mới
  static void updateDataRoom(Map<String, dynamic> roomData) {
    messageNotifierRoom.value = roomData;
  }

  static void updateListUser(List<String> listUser) {
    messageNotifierListUser.value = listUser;
  }

  static void updateRecieveFile(Map<String, dynamic>? listUser) {
    messageNotifierRecieveFile.value = listUser;
  }
}
