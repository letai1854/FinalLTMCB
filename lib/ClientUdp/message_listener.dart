import 'dart:async';
import 'dart:convert'; // Add this import for utf8
import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as logger;

import 'client_state.dart';
import 'constants.dart';
import 'handshake_manager.dart';
import 'json_helper.dart';

class MessageListener {
  final ClientState clientState;
  final HandshakeManager handshakeManager;

  MessageListener(this.clientState, this.handshakeManager);

  Future<void> start() async {
    logger.log('Message listener started.');

    // Listen to socket events
    clientState.socket.listen((RawSocketEvent event) {
      if (!clientState.running) return;

      if (event == RawSocketEvent.read) {
        try {
          // Get the packet
          Datagram? datagram = clientState.socket.receive();
          if (datagram == null) {
            logger.log('Received null datagram from socket.');
            return;
          }

          logger.log(
              'Received packet from ${datagram.address.address}:${datagram.port}, size: ${datagram.data.length} bytes');

          // Determine decryption key (session key if logged in, otherwise fixed key)
          String decryptionKey =
              clientState.sessionKey ?? Constants.FIXED_LOGIN_KEY_STRING;
          logger.log('Attempting decryption with key: $decryptionKey');

          // Attempt decryption and parsing
          var decryptedResult = JsonHelper.decryptAndParse(
              datagram, decryptionKey,
              logTrace: true);

          // If decryption failed with session key, try the fixed key (might be a late login response)
          if (decryptedResult == null && clientState.sessionKey != null) {
            logger
                .log('Decryption failed with session key, trying fixed key...');
            decryptionKey = Constants.FIXED_LOGIN_KEY_STRING;
            decryptedResult = JsonHelper.decryptAndParse(
                datagram, decryptionKey,
                logTrace: true);
          }

          // Special handling for login_success message (can use different key)
          if (decryptedResult == null) {
            logger.log(
                'Standard decryption failed, attempting with additional keys...');
            // Try to extract just enough from the packet to see if it's a login_success message
            String rawContent = _safeDecodeData(datagram.data);
            logger.log('Raw packet content: $rawContent');

            if (rawContent.contains("login_success")) {
              logger.log(
                  'Detected possible login_success message, trying special handling...');
              // This might be encrypted with a new session key from the response
              // We'll try to extract the session key from the raw content
              var matches =
                  RegExp(r'session_key[^\w]+([\w]+)').allMatches(rawContent);
              if (matches.isNotEmpty) {
                String possibleSessionKey = matches.first.group(1) ?? "";
                logger.log(
                    'Found possible session key in message: $possibleSessionKey');
                if (possibleSessionKey.isNotEmpty) {
                  decryptedResult = JsonHelper.decryptAndParse(
                      datagram, possibleSessionKey,
                      logTrace: true);
                }
              }
            }
          }

          // If still failed, log error and skip packet
          if (decryptedResult == null) {
            logger.log(
                'Failed to decrypt or parse packet from server ${datagram.address.address}:${datagram.port}.');
            // Log the raw data for debugging in a safer way
            logger.log('Raw data: ${_safeDecodeData(datagram.data)}');
            return; // Skip this packet
          }

          Map<String, dynamic> responseJson = decryptedResult.jsonObject;
          String decryptedJsonString = decryptedResult.decryptedJsonString;
          logger.log('Successfully decrypted JSON: success');

          // Basic validation: Check for 'action' field
          if (!responseJson.containsKey(Constants.KEY_ACTION)) {
            logger.log(
                'Received packet missing \'action\' field: $decryptedJsonString');
            return; // Skip invalid packet
          }
          String action = responseJson[Constants.KEY_ACTION];
          logger.log('Processing received action: $action');

          // --- Dispatch based on Action ---
          // Handshake-related actions are handled by HandshakeManager
          switch (action) {
            case Constants.ACTION_CHARACTER_COUNT:
              logger.log('Handling CHARACTER_COUNT response');
              handshakeManager.handleCharacterCountResponse(
                  responseJson, datagram.address, datagram.port);
              break;
            case Constants.ACTION_CONFIRM_COUNT:
              logger.log('Handling CONFIRM_COUNT response');
              handshakeManager.handleConfirmCountResponse(
                  responseJson, datagram.address, datagram.port);
              break;
            case Constants.ACTION_ACK:
              logger.log('Handling ACK response');
              handshakeManager.handleServerAck(responseJson);
              break;
            case Constants.ACTION_ERROR:
              logger.log('Handling ERROR response');
              handshakeManager.handleServerError(responseJson);
              break;
            default:
              // If it's not a handshake action, it must be an initial action from the server (S->C flow)
              logger.log('Handling initial server action: $action');
              handshakeManager.handleInitialServerAction(decryptedJsonString,
                  responseJson, datagram.address, datagram.port);
              break;
          }
        } catch (e, stackTrace) {
          if (clientState.running) {
            logger.log('Error processing received packet: $e');
            logger.log('Stack trace: $stackTrace');
          }
        }
      }
    }, onError: (error, stackTrace) {
      if (clientState.running) {
        logger.log('Socket error: $error');
        logger.log('Stack trace: $stackTrace');
      }
    }, onDone: () {
      logger.log('Socket closed.');
    });
  }

  // Helper method to safely decode binary data
  String _safeDecodeData(List<int> data) {
    try {
      // First, clean the data by removing null bytes which can cause issues
      List<int> cleanedData = data.where((byte) => byte != 0).toList();

      // Try Latin-1 encoding first which can represent any byte (0-255)
      // This is more forgiving than UTF-8 for corrupted data
      return String.fromCharCodes(cleanedData);
    } catch (e) {
      try {
        // If even that fails, try decoding in chunks to find valid portions
        List<String> chunks = [];
        for (int i = 0; i < data.length; i += 4) {
          int end = (i + 4 < data.length) ? i + 4 : data.length;
          List<int> chunk = data.sublist(i, end);

          try {
            chunks.add(String.fromCharCodes(chunk));
          } catch (_) {
            // If a chunk fails, represent it as hex
            chunks.add(chunk
                .map((b) => '\\x${b.toRadixString(16).padLeft(2, '0')}')
                .join(''));
          }
        }
        return chunks.join('');
      } catch (e2) {
        // Last resort: convert to hex representation
        return data
            .map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}')
            .join(' ');
      }
    }
  }
}
