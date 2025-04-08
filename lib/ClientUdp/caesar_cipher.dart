import 'dart:developer' as logger;

/// Implements the Caesar Cipher algorithm for basic encryption/decryption.
/// This implementation works with all UTF-8 characters.
class CaesarCipher {
  // We'll use the full UTF-8 range instead of a predefined alphabet

  /// Encrypts plain text using the Caesar cipher with a given key (shift value).
  /// Works with all UTF-8 characters.
  ///
  /// @param plainText The text to encrypt.
  /// @param keyString The key string (its length determines the shift).
  /// @return The encrypted cipher text.
  static String encrypt(String? plainText, String? keyString) {
    if (plainText == null ||
        plainText.isEmpty ||
        keyString == null ||
        keyString.isEmpty) {
      logger.log('Encryption attempt with null or empty input.');
      return plainText ?? '';
    }

    int shift = keyString.length; // Use key length as shift value
    logger.log('Encrypting with shift: $shift');
    return processText(plainText, shift);
  }

  /// Decrypts cipher text using the Caesar cipher with a given key (shift value).
  /// Works with all UTF-8 characters.
  ///
  /// @param cipherText The text to decrypt.
  /// @param keyString The key string (its length determines the shift).
  /// @return The decrypted plain text.
  static String decrypt(String? cipherText, String? keyString) {
    if (cipherText == null ||
        cipherText.isEmpty ||
        keyString == null ||
        keyString.isEmpty) {
      logger.log('Decryption attempt with null or empty input.');
      return cipherText ?? '';
    }

    int shift = keyString.length;
    logger.log('Decrypting with shift: $shift');
    // Decryption is encryption with the negative shift
    return processText(cipherText, -shift);
  }

  /// Helper method to process text for encryption or decryption.
  /// Works with all UTF-8 characters including surrogate pairs.
  ///
  /// @param text The input text.
  /// @param shift The shift value (positive for encrypt, negative for decrypt).
  /// @return The processed text.
  static String processText(String text, int shift) {
    logger.log('Processing text: $text');
    // if (text != null) return text;
    // shift = 0;
    StringBuffer result = StringBuffer();
    int i = 0;

    while (i < text.length) {
      // Xử lý surrogate pairs
      int codePoint;
      if (i + 1 < text.length &&
          _isHighSurrogate(text.codeUnitAt(i)) &&
          _isLowSurrogate(text.codeUnitAt(i + 1))) {
        // Kết hợp surrogate pair thành một code point
        codePoint =
            _combineSurrogatePair(text.codeUnitAt(i), text.codeUnitAt(i + 1));
        i += 2; // Bỏ qua cả hai đơn vị mã
        // logger.log()
        logger.log('Surrogate pair found: $codePoint');
      } else {
        // Ký tự thông thường
        codePoint = text.codeUnitAt(i);
        i++;
      }

      // Áp dụng phép dịch
      int newCodePoint = codePoint + shift;

      // Kiểm tra tính hợp lệ
      if (_isValidCodePoint(newCodePoint)) {
        // Thêm code point mới vào kết quả
        if (newCodePoint > 0xFFFF) {
          // Chuyển đổi lại thành surrogate pair
          final surrogatePair = _toSurrogatePair(newCodePoint);
          result.writeCharCode(surrogatePair.high);
          result.writeCharCode(surrogatePair.low);
        } else {
          result.writeCharCode(newCodePoint);
        }
      } else {
        // Nếu không hợp lệ, giữ nguyên ký tự gốc
        if (codePoint > 0xFFFF) {
          final surrogatePair = _toSurrogatePair(codePoint);
          result.writeCharCode(surrogatePair.high);
          result.writeCharCode(surrogatePair.low);
        } else {
          result.writeCharCode(codePoint);
        }
      }
    }

    return result.toString();
  }

  // Hàm hỗ trợ kiểm tra high surrogate
  static bool _isHighSurrogate(int code) {
    return code >= 0xD800 && code <= 0xDBFF;
  }

  // Hàm hỗ trợ kiểm tra low surrogate
  static bool _isLowSurrogate(int code) {
    return code >= 0xDC00 && code <= 0xDFFF;
  }

  // Hàm hỗ trợ kết hợp surrogate pair thành code point
  static int _combineSurrogatePair(int high, int low) {
    return 0x10000 + ((high & 0x3FF) << 10) + (low & 0x3FF);
  }

  // Hàm hỗ trợ chuyển code point thành surrogate pair
  static ({int high, int low}) _toSurrogatePair(int codePoint) {
    int high = ((codePoint - 0x10000) >> 10) + 0xD800;
    int low = ((codePoint - 0x10000) & 0x3FF) + 0xDC00;
    return (high: high, low: low);
  }

  // Hàm hỗ trợ kiểm tra code point hợp lệ
  static bool _isValidCodePoint(int codePoint) {
    return codePoint >= 0 &&
        codePoint <= 0x10FFFF &&
        !(codePoint >= 0xD800 && codePoint <= 0xDFFF);
  }

  /// Counts the frequency of each character in a string.
  /// Handles all UTF-8 characters including emojis and special characters.
  /// Ensures compatibility with Java server by converting emoji to escaped Unicode sequences.
  ///
  /// @param text The string to analyze.
  /// @return A map with characters as keys and their frequencies as values.
  static Map<String, int> countLetterFrequencies(String? text,
      {bool needProcessSpecialChar = true}) {
    logger.log('Counting letter frequencies in text: ${text ?? "null"}');
    if (text == null || text.isEmpty) {
      return {};
    }

    Map<String, int> frequencies = {};

    // Iterate through the text to count characters, skipping emojis and special multi-character symbols
    for (int i = 0; i < text.length; i++) {
      // Check if this is part of a surrogate pair (likely emoji or other special char)
      if (_isHighSurrogate(text.codeUnitAt(i)) &&
          i + 1 < text.length &&
          _isLowSurrogate(text.codeUnitAt(i + 1))) {
        // Skip this surrogate pair (emoji)
        i++; // Skip the second part of the surrogate pair
        continue;
      }

      // Regular character or Vietnamese letter
      String character = text[i];
      frequencies[character] = (frequencies[character] ?? 0) + 1;
    }

    // Log the character counts for debugging
    logger.log('Character frequencies (excluding emojis): $frequencies');

    return frequencies;
  }

  /// Converts special characters and emoji to their escaped Unicode representation
  /// to match Java's behavior for character frequency counting.
  static String _escapeSpecialCharacters(String text) {
    StringBuffer result = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      int codePoint = text.codeUnitAt(i);

      // Check if this is part of a surrogate pair (emoji or other special char)
      if (_isHighSurrogate(codePoint) &&
          i + 1 < text.length &&
          _isLowSurrogate(text.codeUnitAt(i + 1))) {
        // Combine the surrogate pair into a code point
        int combinedCodePoint =
            _combineSurrogatePair(text.codeUnitAt(i), text.codeUnitAt(i + 1));

        // Convert to \uXXXX escape sequence
        result.write(
            '\\u${combinedCodePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}');
        i++; // Skip the second part of the surrogate pair
      }
      // Check if this is a character that might be handled differently in Java
      else if (codePoint > 127) {
        // Convert to \uXXXX escape sequence for non-ASCII characters
        result.write(
            '\\u${codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}');
      } else {
        // Regular ASCII character
        result.writeCharCode(codePoint);
      }
    }

    return result.toString();
  }

  /// Counts the number of alphabetic characters (a-z, A-Z) in a string.
  /// Used for the confirmation step after decryption.
  ///
  /// @param text The string to analyze.
  /// @return The count of alphabetic characters.
  static int countLetters(String text) {
    if (text.isEmpty) {
      return 0;
    }

    int count = 0;
    for (int i = 0; i < text.length; i++) {
      String c = text[i];
      if (RegExp(r'[a-zA-Z]').hasMatch(c)) {
        count++;
      }
    }
    return count;
  }
}
