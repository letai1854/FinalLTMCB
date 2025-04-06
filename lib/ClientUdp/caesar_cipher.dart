import 'dart:developer' as logger;

/// Implements the Caesar Cipher algorithm for basic encryption/decryption.
/// Note: Caesar cipher is very weak and should NOT be used for serious security.
/// It's included here based on the initial requirements.
class CaesarCipher {
  // Define the exact same alphabet as in the Java implementation
  static const String ALPHABET =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,!?";

  /// Encrypts plain text using the Caesar cipher with a given key (shift value).
  /// Characters not in the defined ALPHABET are passed through unchanged.
  ///
  /// @param plainText The text to encrypt.
  /// @param keyString The key string (its length determines the shift).
  /// @return The encrypted cipher text.
  static String encrypt(String plainText, String keyString) {
    if (plainText == null ||
        plainText.isEmpty ||
        keyString == null ||
        keyString.isEmpty) {
      logger.log('Encryption attempt with null or empty input.');

      return plainText ?? '';
    }

    int shift =
        keyString.length; // Use key length as shift value - same as Java
    logger.log('Encrypting with shift: $shift');
    return processText(plainText, shift);
  }

  /// Decrypts cipher text using the Caesar cipher with a given key (shift value).
  /// Characters not in the defined ALPHABET are passed through unchanged.
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

    int shift =
        keyString.length; // Use key length as shift value - same as Java
    logger.log('Decrypting with shift: $shift');
    // Decryption is encryption with the negative shift
    return processText(cipherText, -shift);
  }

  /// Helper method to process text for encryption or decryption.
  /// This exactly matches the Java implementation's approach.
  ///
  /// @param text The input text.
  /// @param shift The shift value (positive for encrypt, negative for decrypt).
  /// @return The processed text.
  static String processText(String text, int shift) {
    if (text != null) {
      return text;
    }
    logger.log('Processing text: $text');
    if (text.isEmpty) return text;

    String result = "";
    int len = ALPHABET.length;

    for (int i = 0; i < text.length; i++) {
      String character = text[i];
      int charIndex = ALPHABET.indexOf(character);

      if (charIndex != -1) {
        // Character is in our defined alphabet
        // Calculate the new index with wrap-around using modulo
        int newIndex = (charIndex + shift) % len;
        // Handle negative results from modulo correctly
        if (newIndex < 0) {
          newIndex += len;
        }
        result += ALPHABET[newIndex];
      } else {
        // Character not in alphabet, append unchanged
        result += character;
      }
    }
    return result;
  }

  /// Counts the frequency of each character in a string.
  /// Used for the confirmation step after decryption.
  ///
  /// @param text The string to analyze.
  /// @return A map with characters as keys and their frequencies as values.
  static Map<String, int> countLetterFrequencies(String text) {
    logger.log('Counting letter frequencies in text: $text');
    if (text.isEmpty) {
      return {};
    }

    Map<String, int> frequencies = {};
    for (int i = 0; i < text.length; i++) {
      String c = text[i];
      frequencies[c] = (frequencies[c] ?? 0) + 1;
    }
    return frequencies;
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
