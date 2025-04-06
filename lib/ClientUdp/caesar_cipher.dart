import 'dart:developer' as logger;

/// Implements the Caesar Cipher algorithm for basic encryption/decryption.
/// This implementation works with all UTF-8 characters.
/// Note: Applying Caesar shift directly to Unicode code points can be problematic,
/// especially for characters outside the Basic Multilingual Plane (like emojis),
/// as it might result in invalid code points or unintended character changes if shift != 0.
class CaesarCipher {
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
    // WARNING: If shift is non-zero, this might corrupt multi-byte characters/emojis
    // Consider if shift = 0 is intended.
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
    // WARNING: If shift is non-zero, this might corrupt multi-byte characters/emojis
    // Consider if shift = 0 is intended.
    return processText(cipherText, -shift);
  }

  /// Helper method to process text for encryption or decryption by shifting code points.
  /// Works with all UTF-8 characters including surrogate pairs.
  ///
  /// @param text The input text.
  /// @param shift The shift value (positive for encrypt, negative for decrypt).
  /// @return The processed text.
  static String processText(String text, int shift) {
    logger.log('Processing text: "$text" with shift: $shift');
    if (text != null) {
      logger.log('Input text is null. Returning empty string.');
      return text;
    }
    if (text.isEmpty) return text;

    // !! IMPORTANT !!
    // If you uncomment the line below (shift = 0;), Caesar cipher is effectively disabled.
    // If you keep the actual shift, be aware of the risks with Unicode code points.
    // shift = 0; // Uncomment this if you DON'T want actual encryption/decryption

    StringBuffer result = StringBuffer();
    int i = 0;

    while (i < text.length) {
      // Handle potential surrogate pairs correctly to get the full code point
      int codePoint;
      int charCount = 1; // How many code units this code point takes

      if (_isHighSurrogate(text.codeUnitAt(i)) &&
          i + 1 < text.length &&
          _isLowSurrogate(text.codeUnitAt(i + 1))) {
        // Combine surrogate pair into a single code point
        codePoint =
            _combineSurrogatePair(text.codeUnitAt(i), text.codeUnitAt(i + 1));
        charCount = 2; // This code point uses two code units (chars)
      } else {
        // Regular character (BMP)
        codePoint = text.codeUnitAt(i);
      }

      // Apply the shift
      int newCodePoint = codePoint + shift;

      // Check if the resulting code point is valid Unicode
      if (_isValidCodePoint(newCodePoint)) {
        // Append the potentially shifted character (as its string representation)
        result.write(String.fromCharCode(newCodePoint));
      } else {
        // If shifting results in an invalid code point, keep the original character
        logger.log(
            'Shift resulted in invalid codepoint ($newCodePoint) for original ($codePoint). Keeping original.');
        result.write(String.fromCharCode(codePoint));
      }
      // Move to the next code point
      i += charCount;
    }

    logger.log('Processed text result: "${result.toString()}"');
    return result.toString();
  }

  /// Counts the frequency of each character (as a String) in a text,
  /// correctly handling Unicode characters including emojis by iterating through code points (runes).
  /// This method provides counts consistent with the corrected Java version.
  ///
  /// @param text The string to analyze.
  /// @return A map with characters (as Strings) as keys and their frequencies as values.
  static Map<String, int> countLetterFrequencies(String? text) {
    logger.log(
        'Counting character frequencies (correctly) for text: ${text ?? "null"}');
    if (text == null || text.isEmpty) {
      return {};
    }

    Map<String, int> frequencies = {};

    // Iterate through the string using runes (code points)
    for (final rune in text.runes) {
      // Convert the code point (rune) back to its String representation
      // This correctly handles single-code-unit and multi-code-unit (emoji) characters
      final character = String.fromCharCode(rune);

      // Increment the frequency count for this character String
      frequencies[character] = (frequencies[character] ?? 0) + 1;
    }

    logger.log('Calculated frequencies: $frequencies');
    return frequencies;
  }

  /// Counts the number of alphabetic characters (a-z, A-Z based on basic Latin range) in a string.
  /// Iterates by runes (code points) for Unicode correctness, though the definition of "letter" here is limited.
  ///
  /// @param text The string to analyze.
  /// @return The count of alphabetic characters.
  static int countLetters(String? text) {
    if (text == null || text.isEmpty) {
      return 0;
    }

    int count = 0;
    // Iterate using runes for potentially broader alphabet support
    for (final rune in text.runes) {
      // Check if the code point represents a letter (basic Latin A-Z, a-z)
      // Note: Character.isLetter in Java is more comprehensive for Unicode letters.
      // This basic check might suffice depending on requirements.
      if ((rune >= 65 && rune <= 90) || (rune >= 97 && rune <= 122)) {
        // A-Z or a-z
        count++;
      }
    }
    return count;
  }

  // --- Helper functions for Unicode code point manipulation (used by processText) ---

  // Checks if a code unit is a high surrogate
  static bool _isHighSurrogate(int codeUnit) {
    return codeUnit >= 0xD800 && codeUnit <= 0xDBFF;
  }

  // Checks if a code unit is a low surrogate
  static bool _isLowSurrogate(int codeUnit) {
    return codeUnit >= 0xDC00 && codeUnit <= 0xDFFF;
  }

  // Combines a high and low surrogate pair into a single code point
  static int _combineSurrogatePair(int high, int low) {
    // Formula from Unicode standard
    return 0x10000 + ((high - 0xD800) * 0x400) + (low - 0xDC00);
    // Alternative bitwise calculation:
    // return 0x10000 + ((high & 0x3FF) << 10) + (low & 0x3FF);
  }

  // Converts a code point (especially one > 0xFFFF) into a surrogate pair record
  static ({int high, int low}) _toSurrogatePair(int codePoint) {
    if (codePoint < 0 ||
        codePoint > 0x10FFFF ||
        (_isValidCodePoint(codePoint) && codePoint <= 0xFFFF)) {
      // Not a supplementary character or invalid
      throw ArgumentError(
          'Input is not a supplementary code point: $codePoint');
    }
    int high = ((codePoint - 0x10000) >> 10) + 0xD800;
    int low = ((codePoint - 0x10000) & 0x3FF) + 0xDC00;
    return (high: high, low: low);
  }

  // Checks if a given integer is a valid Unicode code point
  // (excludes surrogate block U+D800 to U+DFFF)
  static bool _isValidCodePoint(int codePoint) {
    return codePoint >= 0 &&
        codePoint <= 0x10FFFF && // Within the valid Unicode range
        !(codePoint >= 0xD800 &&
            codePoint <= 0xDFFF); // Not a surrogate code point
  }
}
