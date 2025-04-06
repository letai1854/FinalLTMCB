import 'package:flutter/foundation.dart';

class MessageNotifier {
  static final ValueNotifier<Map<String, dynamic>?> messageNotifier =
      ValueNotifier(null);

  static void updateMessage(Map<String, dynamic> messageData) {
    messageNotifier.value = messageData;
  }
}
