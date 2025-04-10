import 'dart:convert';
import 'dart:io';
import '../Models/file_constants.dart';

class FileJsonHelper {
  static Map<String, dynamic> createFileRequest(
      String action, Map<String, dynamic> data) {
    return {
      'action': action,
      'data': data,
    };
  }

  static bool sendPacket(RawDatagramSocket socket, InternetAddress address,
      int port, Map<String, dynamic> data) {
    try {
      final jsonString = json.encode(data);
      print('Sending packet: $jsonString');
      final bytes = utf8.encode(jsonString);
      socket.send(bytes, address, port);
      return true;
    } catch (e) {
      print('Error sending packet: $e');
      return false;
    }
  }

  static Map<String, dynamic>? decodeMessage(String data) {
    try {
      return json.decode(data) as Map<String, dynamic>;
    } catch (e) {
      print('Error decoding JSON: $e');
      return null;
    }
  }

  static String? safelyDecodeData(List<int> data) {
    try {
      return utf8.decode(data);
    } catch (e) {
      try {
        // Fallback to latin1 if utf8 fails
        return latin1.decode(data);
      } catch (e) {
        print('Error decoding data: $e');
        return null;
      }
    }
  }
}
