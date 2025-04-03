import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'dart:developer' as logger;

import 'package:finalltmcb/ClientUdp/json_helper.dart';
import 'package:finalltmcb/Model/User_model.dart';
import 'package:finalltmcb/Provider/UserProvider.dart';
import 'package:finalltmcb/constants/constants.dart';
import 'package:http/http.dart' as http;
import 'package:finalltmcb/ClientUdp/udpmain.dart'; // Import UdpChatClient
import 'package:finalltmcb/ClientUdp/constants.dart';

class UserController {
  final String _baseEndpoint = '$baseUrl/users';

  // Create a singleton instance of UserController
  static final UserController _instance = UserController._internal();

  // Private constructor
  UserController._internal();

  // Factory constructor to return the singleton instance
  factory UserController() {
    return _instance;
  }

  // Reference to the UDP client
  UdpChatClient? _udpClient;

  // Add public getter for the UDP client
  UdpChatClient? get udpClient => _udpClient;

  final Map<String, Completer<Map<String, dynamic>>> _pendingResponses = {};
  
  int generateChatId() {
    return Random().nextInt(25) + 1; // Returns 1-25
  }

  // Set the UDP client reference
  void setUdpClient(UdpChatClient client) {
    _udpClient = client;
    print("UDP client set in UserController");
  }

  // Login method using UDP client
  Future<User> login(String chatId, String password) async {
    if (_udpClient == null) {
      throw Exception('UDP Client không được khởi tạo. Vui lòng thử lại sau.');
    }
    
    if (chatId.isEmpty || password.isEmpty) {
      throw Exception('Chat ID hoặc mật khẩu không được để trống');
    }
    
    // Create a completer to handle the async response
    final completer = Completer<Map<String, dynamic>>();
    _pendingResponses[chatId] = completer;
    
    try {
      logger.log("Attempting UDP login for user: $chatId");
      
      // Check client state before login
      logger.log("Client state before login - Session key: ${_udpClient!.clientState.sessionKey}, Chat ID: ${_udpClient!.clientState.currentChatId}");
      
      // Register a callback for login response
      _udpClient!.handshakeManager.registerLoginCallback(chatId, (response) {
        logger.log("Received login callback response: $response");
        
        if (!_pendingResponses.containsKey(chatId) || 
            _pendingResponses[chatId]!.isCompleted) {
          logger.log("No pending request found for $chatId or already completed");
          return;
        }
        
        // Complete the future with the response
        _pendingResponses[chatId]!.complete(response);
      });
      
      // Also register error callback to catch authentication failures quickly
      _udpClient!.handshakeManager.registerErrorCallback(chatId, (errorResponse) {
        logger.log("Received error callback for login: $errorResponse");
        
        if (!_pendingResponses.containsKey(chatId) || 
            _pendingResponses[chatId]!.isCompleted) {
          logger.log("No pending request found for $chatId or already completed");
          return;
        }
        
        // Complete the future with the error response
        _pendingResponses[chatId]!.complete({
          'status': 'failure',
          'message': errorResponse['message'] ?? 'Login failed'
        });
      });
      
      // Send login request directly through HandshakeManager to get the result
      final loginResult = await _udpClient!.handshakeManager.sendClientRequestWithAck(
        JsonHelper.createRequest(Constants.ACTION_LOGIN, {
          Constants.KEY_CHAT_ID: chatId,
          Constants.KEY_PASSWORD: password
        }),
        Constants.ACTION_LOGIN,
        Constants.FIXED_LOGIN_KEY_STRING
      );
      
      // If we got a result directly, complete with it
      if (loginResult != null) {
        if (!_pendingResponses[chatId]!.isCompleted) {
          _pendingResponses[chatId]!.complete(loginResult);
        }
      } else {
        // Fallback to command processing if direct request failed
        final loginCommand = "/login $chatId $password";
        logger.log("Direct request failed, trying command: $loginCommand");
        await processCommand(_udpClient!, loginCommand);
      }
      
      // Shorter timeout because we should get responses quickly
      Map<String, dynamic> response;
      try {
        response = await completer.future.timeout(
          const Duration(seconds: 4),
          onTimeout: () => {
            'status': 'timeout',
            'message': 'Đăng nhập hết thời gian chờ. Máy chủ không phản hồi.'
          }
        );
      } catch (e) {
        logger.log("Timeout or error getting login response: $e");
        response = {
          'status': 'error',
          'message': 'Lỗi xử lý đăng nhập: $e'
        };
      }
      
      logger.log("Login response received: $response");
      
      // Check for timeout or error
      if (response['status'] == 'timeout' || response['status'] == 'error') {
        throw Exception(response['message']);
      }
      
      // Check for failed login
      print("--------------- respone---------------------: $response");
      if (response['status'] != Constants.STATUS_SUCCESS) {
        final message = response['message'] ?? 'Đăng nhập thất bại';
        
        // Classify authentication errors
        if (message.toLowerCase().contains('password') || 
            message.toLowerCase().contains('incorrect') ||
            message.toLowerCase().contains('invalid')) {
          throw Exception('Sai mật khẩu, vui lòng kiểm tra lại');
        } else if (message.toLowerCase().contains('user') || 
                  message.toLowerCase().contains('not found') ||
                  message.toLowerCase().contains('does not exist')) {
          throw Exception('Chat ID không tồn tại');
        } else {
          throw Exception('Đăng nhập thất bại: $message');
        }
      }
      
      // Create User object from response
      final user = User(
        chatId: chatId,
        password: password,
        createdAt: DateTime.now()
      );
      
      logger.log("Login successful for user: $chatId");
      return user;
      
    } catch (e) {
      logger.log("Login error: $e");
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      // Always remove the callbacks and pending response
      _udpClient?.handshakeManager.removeLoginCallback(chatId);
      _udpClient?.handshakeManager.removeErrorCallback(chatId);
      _pendingResponses.remove(chatId);
    }
  }

  // Cập nhật thông tin user (keep as is)
  Future<User> updateUser(
      String userId, Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseEndpoint/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception('Cập nhật thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }
}
