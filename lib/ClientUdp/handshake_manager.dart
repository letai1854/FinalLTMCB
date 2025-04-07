import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as logger;

import 'package:uuid/uuid.dart';
import 'package:finalltmcb/Utils/data_converter.dart';

import 'caesar_cipher.dart';
import 'client_state.dart';
import 'constants.dart';
import 'json_helper.dart';
import 'message_processor.dart';

class ClientPendingRequest {
  final String originalAction;
  final String originalSentJson;
  final Completer completer = Completer();
  Map<String, dynamic>? ackData; // Stores the final ACK or ERROR response
  String? serverTransactionId; // Set when CHARACTER_COUNT is received

  ClientPendingRequest(this.originalAction, this.originalSentJson);
}

class HandshakeManager {
  final ClientState clientState;
  final MessageProcessor
      messageProcessor; // To process confirmed server actions

  // --- State Management for Handshake ---
  // Key: Client-generated temporary UUID for C->S flow
  final Map<String, ClientPendingRequest> pendingClientRequestsByTempId = {};
  // Key: Server-generated transactionId for C->S flow (used after CHARACTER_COUNT is received)
  final Map<String, ClientPendingRequest> pendingClientRequestsByServerId = {};
  // Key: Server-generated transactionId for S->C flow
  final Map<String, String> pendingServerActionsJson = {};

  // Add a callback mechanism for login responses
  final Map<String, Function(Map<String, dynamic>)> _loginCallbacks = {};

  // Add a callback mechanism for error responses
  final Map<String, Function(Map<String, dynamic>)> _errorCallbacks = {};

  // Add a callback mechanism for register responses
  final Map<String, Function(Map<String, dynamic>)> _registerCallbacks = {};
  Function(Map<String, dynamic>)? _usersCallbacks;

  HandshakeManager(this.clientState, this.messageProcessor);

  // Register a callback for a specific user's login response
  void registerLoginCallback(
      String chatId, Function(Map<String, dynamic>) callback) {
    _loginCallbacks[chatId] = callback;
    logger.log('Registered login callback for user: $chatId');
  }

  // Remove a callback when no longer needed
  void removeLoginCallback(String chatId) {
    _loginCallbacks.remove(chatId);
    logger.log('Removed login callback for user: $chatId');
  }

  // Register a callback for error responses for a specific user
  void registerErrorCallback(
      String chatId, Function(Map<String, dynamic>) callback) {
    _errorCallbacks[chatId] = callback;
    logger.log('Registered error callback for user: $chatId');
  }

  // Remove an error callback when no longer needed
  void removeErrorCallback(String chatId) {
    _errorCallbacks.remove(chatId);
    logger.log('Removed error callback for user: $chatId');
  }

  // Register a callback for a specific user's register response
  void registerRegisterCallback(
      String chatId, Function(Map<String, dynamic>) callback) {
    _registerCallbacks[chatId] = callback;
    logger.log('Registered register callback for user: $chatId');
  }

  // Remove a register callback when no longer needed
  void removeRegisterCallback(String chatId) {
    _registerCallbacks.remove(chatId);
    logger.log('Removed register callback for user: $chatId');
  }

  void registerUsersCallback(Function(Map<String, dynamic>) callback) {
    _usersCallbacks = callback;
  }

  void removeUsersCallback() {
    _usersCallbacks = null;
  }
  // --- Handling Incoming Handshake Messages ---

  void handleCharacterCountResponse(Map<String, dynamic> response,
      InternetAddress serverAddress, int serverPort) {
    if (!response.containsKey(Constants.KEY_DATA)) {
      logger.log('Received CHARACTER_COUNT missing \'data\' object.');
      return;
    }
    Map<String, dynamic> data = response[Constants.KEY_DATA];

    if (!data.containsKey("transaction_id") ||
        !data.containsKey(Constants.KEY_LETTER_FREQUENCIES) ||
        !data.containsKey(Constants.KEY_ORIGINAL_ACTION)) {
      logger.log(
          'Received CHARACTER_COUNT missing transaction_id, frequencies, or original_action within \'data\'.');
      return;
    }

    String transactionId = data["transaction_id"];
    String originalAction = data[Constants.KEY_ORIGINAL_ACTION];
    Map<String, dynamic> serverFrequenciesJson =
        data[Constants.KEY_LETTER_FREQUENCIES];
    logger.log(
        'Received CHARACTER_COUNT for original action \'$originalAction\', server tx ID: $transactionId');

    ClientPendingRequest? pendingReq;
    String? tempIdToRemove;

    pendingClientRequestsByTempId.forEach((tempId, req) {
      if (req.originalAction == originalAction &&
          req.serverTransactionId == null) {
        pendingReq = req;
        tempIdToRemove = tempId;
        logger.log(
            'Found matching pending request (TempID: $tempIdToRemove) for original action $originalAction');
      }
    });

    if (pendingReq == null) {
      logger.log(
          'Received CHARACTER_COUNT for original action \'$originalAction\', but no matching pending request found or it was already processed (Server TxID: $transactionId).');
      return;
    }

    pendingReq!.serverTransactionId = transactionId;
    if (tempIdToRemove != null) {
      pendingClientRequestsByTempId.remove(tempIdToRemove);
    } else {
      logger.log(
          'Could not find tempIdToRemove while processing CHARACTER_COUNT for tx $transactionId');
    }

    pendingClientRequestsByServerId[transactionId] = pendingReq!;
    logger.log(
        'Associated server tx ID $transactionId with pending action $originalAction (TempID: $tempIdToRemove)');

    Map<String, int> clientCalculatedFrequencies = CaesarCipher.countLetterFrequencies(pendingReq!.originalSentJson, needProcessSpecialChar: false);
    Map<String, int> serverFrequencies = parseFrequencyJson(serverFrequenciesJson);
    bool isValid = areFrequenciesEqual(clientCalculatedFrequencies, serverFrequencies);

    if (!isValid) {
      logger.log(
          'Frequency check failed for transaction: $transactionId. Client: $clientCalculatedFrequencies, Server: $serverFrequencies');
    } else {
      logger.log('Frequency check successful for transaction: $transactionId');
    }

    Map<String, dynamic> confirmData = {
      "transaction_id": transactionId,
      Constants.KEY_CONFIRM: isValid
    };

    Map<String, dynamic> confirmRequest =
        JsonHelper.createRequest(Constants.ACTION_CONFIRM_COUNT, confirmData);
    String key = clientState.sessionKey ?? Constants.FIXED_LOGIN_KEY_STRING;
    JsonHelper.sendPacket(
        clientState.socket, serverAddress, serverPort, confirmRequest, key);
    logger.log(
        'Sent CONFIRM_COUNT (confirmed: $isValid) for transaction: $transactionId');
  }

  void handleConfirmCountResponse(Map<String, dynamic> response,
      InternetAddress serverAddress, int serverPort) {
    if (!response.containsKey(Constants.KEY_DATA)) {
      logger.log('Received CONFIRM_COUNT missing \'data\' object.');
      return;
    }
    Map<String, dynamic> data = response[Constants.KEY_DATA];

    if (!data.containsKey("transaction_id") ||
        !data.containsKey(Constants.KEY_CONFIRM)) {
      logger.log(
          'Received CONFIRM_COUNT missing \'transaction_id\' or \'confirm\' field within \'data\'.');
      return;
    }

    String transactionId = data["transaction_id"];
    bool confirmed = data[Constants.KEY_CONFIRM];
    logger.log(
        'Received CONFIRM_COUNT for transaction: $transactionId (confirmed: $confirmed)');

    String? pendingJson = pendingServerActionsJson.remove(transactionId);
    if (pendingJson == null) {
      logger.log(
          'No pending server action found for transaction: $transactionId');
    }

    String ackStatus = Constants.STATUS_FAILURE;
    String? ackMessage;

    if (confirmed) {
      if (pendingJson != null) {
        // Delegate processing to MessageProcessor
        messageProcessor.processServerAction(pendingJson);
        ackStatus = Constants.STATUS_SUCCESS;
      } else {
        ackMessage = "Client lost original action state.";
        logger.log(
            'Cannot process action for transaction $transactionId because pending JSON was lost.');
      }
    } else {
      ackStatus = Constants.STATUS_CANCELLED;
      ackMessage = "Frequency mismatch detected by server.";
      logger.log(
          'Server indicated frequency mismatch for transaction: $transactionId, not processing');
    }

    sendAck(transactionId, ackStatus, ackMessage, serverAddress, serverPort);
  }

  void handleServerAck(Map<String, dynamic> responseJson) {
    if (!responseJson.containsKey(Constants.KEY_STATUS)) {
      logger.log('Received ACK missing status field.');
      return;
    }
    String status = responseJson[Constants.KEY_STATUS];

    if (!responseJson.containsKey(Constants.KEY_DATA)) {
      logger.log('Received ACK missing \'data\' object.');
      return;
    }
    Map<String, dynamic> data = responseJson[Constants.KEY_DATA];

    if (!data.containsKey("transaction_id")) {
      logger.log(
          'Received ACK missing \'transaction_id\' field within \'data\'.');
      return;
    }
    String transactionId = data["transaction_id"];
    String originalAction = data.containsKey(Constants.KEY_ORIGINAL_ACTION)
        ? data[Constants.KEY_ORIGINAL_ACTION]
        : "unknown";
    logger.log(
        'Received Server ACK for transaction: $transactionId (Original Action: $originalAction) with status: $status');
    logger.log('Full ACK response: $responseJson');

    if (responseJson.containsKey(Constants.KEY_MESSAGE)) {
      var messageStr = responseJson[Constants.KEY_MESSAGE] as String;
      try {
        // Use DataConverter to process the handshake data
        clientState.sessionKey = data[Constants.KEY_SESSION_KEY];
        clientState.currentChatId = data[Constants.KEY_CHAT_ID];
        var result =
            DataConverter.processHandshakeData(clientState, messageStr);
        if (result != null && result['success'] == true) {
          logger.log("Data converted and stored successfully");
          // Notify any registered callbacks about the updated data
          if (_usersCallbacks != null) {
            _usersCallbacks!({
              'status': Constants.STATUS_SUCCESS,
              'users': clientState.convertedUsers,
              'cachedMessages': clientState.cachedMessages,
              'roomMessages': clientState.roomMessages
            });
          }
        }
      } catch (e) {
        logger
            .log("Error parsing message JSON: $e\nMessage string: $messageStr");
      }
    }
    ClientPendingRequest? pendingReq =
        pendingClientRequestsByServerId.remove(transactionId);

    if (pendingReq != null) {
      pendingReq.ackData = responseJson; // Store the full ACK response
      logger.log(
          'Found pending request for transaction: $transactionId (Action: $originalAction)');

      if (Constants.ACTION_LOGIN == originalAction) {
        if (Constants.STATUS_SUCCESS == status) {
          if (data.containsKey(Constants.KEY_SESSION_KEY) &&
              data.containsKey(Constants.KEY_CHAT_ID)) {
            clientState.sessionKey = data[Constants.KEY_SESSION_KEY];
            clientState.currentChatId = data[Constants.KEY_CHAT_ID];

            logger.log(
                'Login successful via ACK! Updated sessionKey for user \'${clientState.currentChatId}\'. Session: ${clientState.sessionKey}');
            print("\nLogin successful! Welcome ${clientState.currentChatId}.");
            print("Type /help");

            // Notify any registered callbacks about the login response
            String chatId = data[Constants.KEY_CHAT_ID];
            if (_loginCallbacks.containsKey(chatId)) {
              logger.log('Invoking login callback for user: $chatId');
              _loginCallbacks[chatId]!({
                'status': Constants.STATUS_SUCCESS,
                'message': 'Login successful',
                'chatId': chatId,
                'sessionKey': clientState.sessionKey,
              });
              _loginCallbacks.remove(chatId); // Remove after use
            } else {
              logger.log('No login callback found for user: $chatId');
            }
          } else {
            logger.log(
                'Login ACK successful but missing session_key or chatid in data! Data: $data');
            print(
                "\nLogin successful, but server response was incomplete. Please try again.");
          }
        } else {
          // Login Failed via ACK
          String message = responseJson.containsKey(Constants.KEY_MESSAGE)
              ? responseJson[Constants.KEY_MESSAGE]
              : "Unknown reason";
          logger
              .log('Login failed via ACK. Status: $status, Message: $message');
          print("\nLogin failed: $message (Status: $status)");

          // Notify callback about failed login if we can identify the user
          if (data.containsKey(Constants.KEY_CHAT_ID)) {
            String chatId = data[Constants.KEY_CHAT_ID];
            // Use the correct callback map (_loginCallbacks)
            if (_loginCallbacks.containsKey(chatId)) {
              logger.log('Invoking login failure callback for user: $chatId');
              _loginCallbacks[chatId]!({
                'status': status,
                'message': message,
              });
              _loginCallbacks.remove(chatId); // Remove after use
            } else {
              logger.log('No login callback found for user: $chatId');
            }
          } else {
            logger.log(
                'Login failed but no chatId found in data to invoke callback. Data: $data');
          }
          // Complete the completer even on failure
          pendingReq.completer.complete(true);
          logger.log(
              'Signaled completion (failure) for pending login request associated with transaction $transactionId');
        } // End Login Failed via ACK
      } else if (Constants.ACTION_REGISTER == originalAction) {
        // Handle ACK for REGISTER action
        String chatId = data.containsKey(Constants.KEY_CHAT_ID)
            ? data[Constants.KEY_CHAT_ID]
            : "unknown_user";
        if (Constants.STATUS_SUCCESS == status) {
          logger.log('Registration successful via ACK for user \'$chatId\'.');
          // Optionally update state or notify callback if needed based on ACK
          if (_registerCallbacks.containsKey(chatId)) {
            logger.log(
                'Invoking register success callback via ACK for user: $chatId');
            _registerCallbacks[chatId]!(responseJson); // Pass the whole ACK
            _registerCallbacks.remove(chatId);
          }
        } else {
          // Registration Failed via ACK
          String message = responseJson.containsKey(Constants.KEY_MESSAGE)
              ? responseJson[Constants.KEY_MESSAGE]
              : "Unknown reason";
          logger.log(
              'Registration failed via ACK for user \'$chatId\'. Status: $status, Message: $message');
          print("\nRegistration failed: $message (Status: $status)");
          // Notify register callback about failure
          if (_registerCallbacks.containsKey(chatId)) {
            logger.log(
                'Invoking register failure callback via ACK for user: $chatId');
            _registerCallbacks[chatId]!(responseJson); // Pass the whole ACK
            _registerCallbacks.remove(chatId);
          }
        }
        pendingReq.completer.complete(true);
        logger.log(
            'Signaled completion for pending register request associated with transaction $transactionId');
      } else {
        // Handle ACK for other actions
        pendingReq.completer.complete(true);
        logger.log(
            'Signaled completion for pending request (Action: $originalAction) associated with transaction $transactionId');
      }
    } else {
      logger.log(
          'Received ACK for unknown, timed-out, or already processed transaction: $transactionId. Full ACK: $responseJson');
    }
  }

  void handleServerError(Map<String, dynamic> responseJson) {
    String errorMessage = responseJson.containsKey(Constants.KEY_MESSAGE)
        ? responseJson[Constants.KEY_MESSAGE]
        : "Unknown server error";
    String originalAction =
        responseJson.containsKey(Constants.KEY_ORIGINAL_ACTION)
            ? responseJson[Constants.KEY_ORIGINAL_ACTION]
            : "unknown";
    logger.log(
        'Received ERROR from server for action \'$originalAction\': $errorMessage');
    print("\nServer Error ($originalAction): $errorMessage");

    // Handle specific errors by calling the appropriate error callback
    if (responseJson.containsKey(Constants.KEY_DATA)) {
      Map<String, dynamic> data = responseJson[Constants.KEY_DATA];
      if (data.containsKey(Constants.KEY_CHAT_ID)) {
        String chatId = data[Constants.KEY_CHAT_ID];
        Function(Map<String, dynamic>)? errorCallback;

        if (originalAction == Constants.ACTION_LOGIN) {
          errorCallback = _errorCallbacks[chatId];
        } else if (originalAction == Constants.ACTION_REGISTER) {
          // Decide if register errors should also use the general error callback
          // or a specific register error callback if you add one.
          errorCallback =
              _errorCallbacks[chatId]; // Using general error callback for now
        }
        // Add more else if for other actions if needed

        if (errorCallback != null) {
          logger.log(
              'Invoking error callback for action \'$originalAction\' of user: $chatId');
          errorCallback(responseJson);
          _errorCallbacks
              .remove(chatId); // Remove general error callback after use
          // If using specific error callbacks, remove the specific one here.
        } else {
          logger.log(
              'No specific error callback found for action \'$originalAction\' of user: $chatId');
        }
      } else {
        logger.log(
            'Server ERROR received but no chatId found in data. Data: $data');
      }
    } else {
      logger.log(
          'Server ERROR received but no data field found. Response: $responseJson');
    }

    ClientPendingRequest? pendingReqToFail;
    String? tempIdToFail;
    String? serverIdToFail;

    if (responseJson.containsKey(Constants.KEY_DATA)) {
      Map<String, dynamic> data = responseJson[Constants.KEY_DATA];
      if (data.containsKey("transaction_id")) {
        serverIdToFail = data["transaction_id"];
        pendingReqToFail = pendingClientRequestsByServerId[serverIdToFail];
      }
    }

    if (pendingReqToFail == null) {
      pendingClientRequestsByTempId.forEach((tempId, req) {
        if (req.originalAction == originalAction) {
          pendingReqToFail = req;
          tempIdToFail = tempId;
          serverIdToFail = req.serverTransactionId;
        }
      });
    }

    if (pendingReqToFail != null) {
      logger.log(
          'Signaling failure for pending action $originalAction due to server error.');
      pendingReqToFail!.ackData = responseJson; // Store error info
      pendingReqToFail!.completer
          .complete(true); // Signal completion (as failure)
      if (tempIdToFail != null)
        pendingClientRequestsByTempId.remove(tempIdToFail);
      if (serverIdToFail != null)
        pendingClientRequestsByServerId.remove(serverIdToFail);
    } else {
      logger.log(
          'Could not find pending request for action \'$originalAction\' to signal server error.');
    }
    stdout.write("> ");
  }

  // --- Handling Server-Initiated Actions (S->C Flow) ---

  void handleInitialServerAction(
      String decryptedJsonString,
      Map<String, dynamic> responseJson,
      InternetAddress serverAddress,
      int serverPort) {
    logger.log(
        'Received initial action \'${responseJson[Constants.KEY_ACTION]}\' from server, starting S->C flow');
    String? transactionId;

    if (responseJson.containsKey(Constants.KEY_DATA)) {
      Map<String, dynamic> data = responseJson[Constants.KEY_DATA];
      if (data.containsKey("transaction_id")) {
        transactionId = data["transaction_id"];
      }
    }

    if (transactionId == null) {
      logger.log(
          'Server message action \'${responseJson[Constants.KEY_ACTION]}\' missing \'transaction_id\'. Cannot proceed.');
      return;
    }

    pendingServerActionsJson[transactionId] = decryptedJsonString;
    String action = responseJson[Constants.KEY_ACTION];
    if (action == Constants.ACTION_LOGIN_SUCCESS) {
      if (responseJson.containsKey(Constants.KEY_DATA)) {
        Map<String, dynamic> data = responseJson[Constants.KEY_DATA];
        if (data.containsKey(Constants.KEY_SESSION_KEY) &&
            data.containsKey(Constants.KEY_CHAT_ID)) {
          clientState.sessionKey = data[Constants.KEY_SESSION_KEY];
          clientState.currentChatId = data[Constants.KEY_CHAT_ID];
          logger.log(
              'Login successful via S->C flow! Updated sessionKey for user \'${clientState.currentChatId}\'. Session: ${clientState.sessionKey}');
          print("\nLogin successful! Welcome ${clientState.currentChatId}.");
          print("Type /help");
        } else {
          logger.log(
              'Login SUCCESS via S->C flow but missing session_key or chatid in data! Data: $data');
          print(
              "\nLogin successful, but server response was incomplete. Please try again.");
        }
      } else {
        logger.log('Login SUCCESS via S->C flow but missing data!');
        print(
            "\nLogin successful, but server response was incomplete. Please try again.");
      }
    } else {
      pendingServerActionsJson[transactionId] = decryptedJsonString;
      sendCharacterCount(
          decryptedJsonString, transactionId, serverAddress, serverPort);
    }
  }

  // --- Sending Handshake Messages ---

  void sendCharacterCount(String receivedJsonString, String transactionId,
      InternetAddress serverAddress, int serverPort) {
    try {
      Map<String, int> freqMap =
          CaesarCipher.countLetterFrequencies(receivedJsonString);
      Map<String, dynamic> frequenciesJson = {};

      freqMap.forEach((key, value) {
        frequenciesJson[key] = value;
      });

      Map<String, dynamic> data = {
        "transaction_id": transactionId,
        Constants.KEY_LETTER_FREQUENCIES: frequenciesJson
      };

      Map<String, dynamic> request =
          JsonHelper.createRequest(Constants.ACTION_CHARACTER_COUNT, data);
      // Use sessionKey if available, otherwise fixed key (should only be null for S->C before login)
      String key = clientState.sessionKey ?? Constants.FIXED_LOGIN_KEY_STRING;
      JsonHelper.sendPacket(
          clientState.socket, serverAddress, serverPort, request, key);
      logger.log(
          'Sent CHARACTER_COUNT for server-initiated transaction: $transactionId');
    } catch (e) {
      logger.log(
          'Error sending CHARACTER_COUNT for transaction $transactionId: $e');
    }
  }

  void sendAck(String transactionId, String status, String? message,
      InternetAddress serverAddress, int serverPort) {
    try {
      Map<String, dynamic> data = {"transaction_id": transactionId};

      Map<String, dynamic> request =
          JsonHelper.createReply(Constants.ACTION_ACK, status, message, data);
      // Use sessionKey if available
      String key = clientState.sessionKey ?? Constants.FIXED_LOGIN_KEY_STRING;
      JsonHelper.sendPacket(
          clientState.socket, serverAddress, serverPort, request, key);
      logger
          .log('Sent ACK for transaction: $transactionId with status: $status');
    } catch (e) {
      logger.log('Error sending ACK for transaction $transactionId: $e');
    }
  }

  // --- Sending Client-Initiated Requests with Handshake ---

  Future<Map<String, dynamic>?> sendClientRequestWithAck(
      Map<String, dynamic> request, String action, String encryptionKey) async {
    var uuid = Uuid();
    String tempId = uuid.v4();
    String jsonToSend = json.encode(request);
    logger.log("json to send " + jsonToSend);
    ClientPendingRequest pendingReq = ClientPendingRequest(action, jsonToSend);
    pendingClientRequestsByTempId[tempId] = pendingReq;

    try {
      bool sendResult = JsonHelper.sendPacket(
          clientState.socket,
          clientState.serverAddress,
          clientState.serverPort,
          request,
          encryptionKey);

      if (!sendResult) {
        logger
            .log('Failed to send packet for action: $action (TempID: $tempId)');
        return {
          'status': 'error',
          'message': 'Could not send request to server'
        };
      }

      logger.log(
          'Sent action: $action (TempID: $tempId) - waiting for server CHARACTER_COUNT...');

      // Set up a timeout and properly handle different completion types
      dynamic result;
      try {
        result =
            await pendingReq.completer.future.timeout(Duration(seconds: 30));
      } catch (e) {
        if (e is TimeoutException) {
          result = null; // Timeout occurred
        } else {
          rethrow; // Other error, rethrow it
        }
      }

      bool completed =
          result != null; // If we got any result, consider it completed

      pendingClientRequestsByTempId.remove(tempId);
      if (pendingReq.serverTransactionId != null) {
        pendingClientRequestsByServerId.remove(pendingReq.serverTransactionId);
      }

      if (!completed) {
        logger.log(
            'Timeout waiting for server ACK for action: $action (TempID: $tempId)');
        print("\nRequest timed out. Server did not respond.");
        return {
          'status': 'timeout',
          'message': 'Server did not respond in time'
        };
      } else {
        Map<String, dynamic>? ackResponse = pendingReq.ackData;
        if (ackResponse != null &&
            ackResponse.containsKey(Constants.KEY_STATUS)) {
          String status = ackResponse[Constants.KEY_STATUS];
          String serverMessage = ackResponse.containsKey(Constants.KEY_MESSAGE)
              ? ackResponse[Constants.KEY_MESSAGE]
              : "No details";

          if (status != Constants.STATUS_SUCCESS) {
            logger.log(
                'Action $action (TempID: $tempId) failed on server. Status: $status, Message: $serverMessage');

            // For login failures, return the status and message
            if (action == Constants.ACTION_LOGIN) {
              return {'status': status, 'message': serverMessage};
            }

            // Display error for non-login actions
            print(
                "\nServer couldn't process request: $serverMessage (Status: $status)");

            return {'status': status, 'message': serverMessage};
          } else {
            logger.log(
                'Action $action (TempID: $tempId) acknowledged successfully by server.');

            // For login success, return session info if available
            if (action == Constants.ACTION_LOGIN &&
                ackResponse.containsKey(Constants.KEY_DATA)) {
              Map<String, dynamic> data = ackResponse[Constants.KEY_DATA];
              return {
                'status': Constants.STATUS_SUCCESS,
                'message': 'Login successful',
                'chatId': data.containsKey(Constants.KEY_CHAT_ID)
                    ? data[Constants.KEY_CHAT_ID]
                    : null,
                'sessionKey': data.containsKey(Constants.KEY_SESSION_KEY)
                    ? data[Constants.KEY_SESSION_KEY]
                    : null
              };
            }

            // Specific success messages for non-login actions
            if (action == Constants.ACTION_SEND_MESSAGE)
              print("\nMessage sent successfully!");
            else if (action == Constants.ACTION_CREATE_ROOM)
              print("\nRoom creation request acknowledged.");

            return {
              'status': Constants.STATUS_SUCCESS,
              'message': serverMessage
            };
          }
        } else if (ackResponse != null &&
            ackResponse.containsKey(Constants.KEY_ACTION) &&
            Constants.ACTION_ERROR == ackResponse[Constants.KEY_ACTION]) {
          // Error was already logged by handleServerError, just log completion here
          logger.log(
              'Action $action (TempID: $tempId) completed with server ERROR.');

          String errorMessage = ackResponse.containsKey(Constants.KEY_MESSAGE)
              ? ackResponse[Constants.KEY_MESSAGE]
              : "Unknown error";

          return {'status': 'error', 'message': errorMessage};
        } else {
          logger.log(
              'ACK/ERROR received for action $action (TempID: $tempId) but status/format missing/invalid.');
          print("\nReceived invalid response from server.");

          return {
            'status': 'error',
            'message': 'Invalid server response format'
          };
        }
      }
    } catch (e) {
      logger.log('Unexpected error sending $action (TempID: $tempId): $e');
      print("Error: $e");
      pendingClientRequestsByTempId.remove(tempId);

      return {'status': 'error', 'message': 'Exception: $e'};
    } finally {
      stdout.write("> ");
    }
  }

  // --- Utility Methods ---

  Map<String, int> parseFrequencyJson(Map<String, dynamic> freqJson) {
    Map<String, int> map = {};
    freqJson.forEach((key, value) {
      if (key.length == 1) {
        try {
          map[key] = value;
        } catch (e) {
          logger.log('Invalid frequency value for key \'$key\': $value');
        }
      } else {
        logger.log('Invalid frequency key (not single char): \'$key\'');
      }
    });
    return map;
  }

  bool areFrequenciesEqual(Map<String, int> map1, Map<String, int> map2) {
    if (map1.length != map2.length) return false;

    for (var key in map1.keys) {
      if (!map2.containsKey(key) || map2[key] != map1[key]) {
        return false;
      }
    }

    return true;
  }

  // Method to clean up pending requests on shutdown
  void shutdown() {
    logger.log('Shutting down HandshakeManager, clearing pending requests.');
    pendingClientRequestsByTempId.clear();
    pendingClientRequestsByServerId.clear();
    pendingServerActionsJson.clear();
  }
}
