import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as logger;

import 'caesar_cipher.dart';
import 'constants.dart';

class DecryptedResult {
  final Map<String, dynamic> jsonObject;
  final String decryptedJsonString;

  DecryptedResult(this.jsonObject, this.decryptedJsonString);
}

/**
 * Utility class for handling JSON parsing, creation, encryption/decryption, and UDP packet sending.
 */
class JsonHelper {
  /**
   * Creates a standard JSON request object.
   */
  static Map<String, dynamic> createRequest(
      String action, Map<String, dynamic>? data) {
    Map<String, dynamic> request = {
      Constants.KEY_ACTION: action,
    };

    if (data != null) {
      request[Constants.KEY_DATA] = data;
    }

    return request;
  }

  /**
   * Wrapper class to hold the result of decryption and parsing.
   */

  /**
   * Decrypts the data from a DatagramPacket using the provided key string,
   * then parses it into a JsonObject.
   */
  static DecryptedResult? decryptAndParse(Datagram packet, String keyString,
      {bool logTrace = false}) {
    if (packet.data.isEmpty) {
      logger.log('Received empty packet for decryption.');
      return null;
    }
    if (keyString.isEmpty) {
      logger.log(
          'Attempted decryption with empty key from ${packet.address.address}:${packet.port}');
      return null;
    }

    try {
      // Assume the entire data payload is the encrypted string
      String encryptedString = utf8.decode(packet.data, allowMalformed: true);

      if (logTrace) {}

      // Decrypt using Caesar cipher
      String decryptedJsonString =
          CaesarCipher.decrypt(encryptedString, keyString);
      if (decryptedJsonString.isEmpty) {
        logger.log(
            'Decryption returned empty string for packet from ${packet.address.address}:${packet.port} with key length ${keyString.length}');
        return null; // Decryption failed critically
      }

      if (logTrace) {
        logger.log('Decrypted JSON string: ');
      }

      // Fix common Caesar cipher decryption issues before parsing
      decryptedJsonString = _fixCommonDecryptionIssues(decryptedJsonString);

      // Parse the decrypted string
      Map<String, dynamic> jsonObject = json.decode(decryptedJsonString);
      return DecryptedResult(jsonObject, decryptedJsonString);
    } catch (e) {
      // Log the decrypted string only if tracing is enabled
      if (logTrace) {
        try {
          String partialDecryption = CaesarCipher.decrypt(
              utf8.decode(packet.data, allowMalformed: true), keyString);
          logger.log(
              'Invalid JSON syntax after decryption with key length ${keyString.length} from ${packet.address.address}:${packet.port}. '
              'Decrypted content (potential garbage): \'$partialDecryption\'. Error: $e');
        } catch (innerError) {
          logger.log('Error during decryption logging: $innerError');
        }
      } else {
        logger.log(
            'Invalid JSON syntax after decryption with key length ${keyString.length} from ${packet.address.address}:${packet.port}. '
            'Error: $e');
      }
      return null;
    }
  }

  /**
   * Fixes common issues with Caesar cipher decryption before JSON parsing
   */
  static String _fixCommonDecryptionIssues(String decryptedText) {
    // Check if alphabet mapping is causing issues by debugging comma positions
    logger.log('Original decrypted text before fix: ');

    // 1. Replace 'E' with ',' when it appears between quoted strings in JSON
    String fixed = decryptedText.replaceAll(RegExp(r'"\s*E\s*"'), '","');

    // 2. Fix key-value pairs separator (E instead of comma)
    fixed = fixed.replaceAll(RegExp(r'"\s*E\s*(?=\w+":)'), '","');

    // 3. Directly replace all standalone E characters likely to be commas in JSON context
    fixed =
        fixed.replaceAll(RegExp(r'(?<=[\{\]\w"])\s*E\s*(?=[\{\[\w"])'), ',');

    // 4. General comma fix for any obvious JSON syntax
    fixed = fixed.replaceAll('"E"', '","');
    fixed = fixed.replaceAll('"E{', '",{');
    fixed = fixed.replaceAll('}E"', '},"');
    fixed = fixed.replaceAll('}E{', '},{');

    logger.log('Fixed decrypted text: $fixed');
    return fixed;
  }

  /**
   * Creates a standard JSON reply object.
   */
  static Map<String, dynamic> createReply(String action, String status,
      String? message, Map<String, dynamic>? data) {
    Map<String, dynamic> reply = {
      Constants.KEY_ACTION: action,
      Constants.KEY_STATUS: status,
    };

    if (message != null) {
      reply[Constants.KEY_MESSAGE] = message;
    }

    if (data != null) {
      reply[Constants.KEY_DATA] = data;
    }

    return reply;
  }

  /**
   * Creates a standard JSON error reply object.
   */
  static Map<String, dynamic> createErrorReply(
      String originalAction, String errorMessage) {
    return {
      Constants.KEY_ACTION: Constants.ACTION_ERROR,
      'original_action': originalAction,
      Constants.KEY_STATUS: Constants.STATUS_ERROR,
      Constants.KEY_MESSAGE: errorMessage,
    };
  }

  /**
   * Encrypts a JsonObject using the provided key and sends it as a UDP DatagramPacket.
   * Returns true if sending was successful, false if an error occurred.
   */
  static bool sendPacket(RawDatagramSocket socket, InternetAddress address,
      int port, Map<String, dynamic> jsonData, String encryptionKey) {
    if (socket == null || address == null || jsonData == null) {
      logger.log(
          'Attempted to send packet with null socket, address, or JSON data.');
      return false;
    }
    if (encryptionKey.isEmpty) {
      logger.log(
          'Attempted encryption with empty key for packet to ${address.address}:$port');
      return false;
    }

    try {
      // Convert Dart Map to JSON string - this is equivalent to gson.toJson() in Java
      String jsonString =
          json.encode(jsonData); // This is serialization, not encryption
      logger.log('JSON string to send: $jsonString');

      // Now encrypt the JSON string using Caesar cipher
      String encryptedText = CaesarCipher.encrypt(jsonString, encryptionKey);
      logger.log(
          'Encrypted with key: "$encryptionKey", length: ${encryptionKey.length}');

      // Log detailed encryption info for debugging
      logger.log('Sending encrypted text: $encryptedText');
      print(
          '--------------------------------------Encrypted JSON string to send: $encryptedText'); // For debugging

      // Convert to bytes and send
      List<int> data = utf8.encode(encryptedText);
      logger.log('Sending ${data.length} bytes to ${address.address}:$port');

      // Check packet size
      if (data.length > Constants.MAX_UDP_PACKET_SIZE) {
        logger.log(
            'Attempted to send UDP packet larger than max size (${data.length} bytes) after encryption to ${address.address}:$port');
        return false;
      }

      socket.send(data, address, port);

      // Log successful send with action information
      String action = jsonData.containsKey(Constants.KEY_ACTION)
          ? jsonData[Constants.KEY_ACTION]
          : "unknown";
      logger.log(
          'Sent encrypted packet (action: $action) with key length ${encryptionKey.length} to ${address.address}:$port');

      return true;
    } catch (e, stackTrace) {
      logger.log(
          'Error sending encrypted UDP packet to ${address.address}:$port: $e');
      logger.log('Stack trace: $stackTrace');
      return false;
    }
  }

  // Helper method to convert bytes to hex for debugging
  static String _byteToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  }

  // Add a utility method to make the conversion more explicit
  static String toJsonString(Map<String, dynamic> data) {
    // This method is equivalent to gson.toJson() in Java
    return json.encode(data);
  }
}
