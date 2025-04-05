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
  
  try {
    // Xóa các callback cũ nếu có
    _udpClient?.handshakeManager.removeLoginCallback(chatId);
    _udpClient?.handshakeManager.removeRegisterCallback(chatId);
    _udpClient?.handshakeManager.removeErrorCallback(chatId);
    _pendingResponses.remove(chatId);
    
    // Tạo completer mới
    final completer = Completer<Map<String, dynamic>>();
    _pendingResponses[chatId] = completer;
    
    // Đăng ký callback cho phản hồi đăng nhập
    _udpClient!.handshakeManager.registerLoginCallback(chatId, (response) {
      if (!_pendingResponses.containsKey(chatId) || 
          _pendingResponses[chatId]!.isCompleted) return;
      _pendingResponses[chatId]!.complete(response);
    });
    
    // Đăng ký callback cho lỗi
    _udpClient!.handshakeManager.registerErrorCallback(chatId, (errorResponse) {
      if (!_pendingResponses.containsKey(chatId) || 
          _pendingResponses[chatId]!.isCompleted) return;
      _pendingResponses[chatId]!.complete({
        'status': 'failure',
        'message': errorResponse['message'] ?? 'Login failed'
      });
    });
    
    // Gửi lệnh đăng nhập
    await _udpClient?.commandProcessor.processCommand("/login $chatId $password");
    
    // Đợi kết quả với timeout
    Map<String, dynamic> response = await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => {
        'status': 'timeout',
        'message': 'Đăng nhập thất bại.'
      }
    );
    
    // Kiểm tra lỗi
    if (response['status'] != Constants.STATUS_SUCCESS) {
      throw Exception(response['message'] ?? 'Đăng nhập thất bại');
    }
    
    // Tạo user object khi đăng nhập thành công
    final user = User(
      chatId: chatId,
      password: password,
      createdAt: DateTime.now()
    );
    
    return user;
  } catch (e) {
    throw Exception(e.toString().replaceAll('Exception: ', ''));
  } finally {
    // Luôn xóa callbacks
    _udpClient?.handshakeManager.removeLoginCallback(chatId);
    _udpClient?.handshakeManager.removeErrorCallback(chatId);
    _pendingResponses.remove(chatId);
  }
}

Future<User> register(String username, String password) async {
  if (_udpClient == null) {
    throw Exception('UDP Client không được khởi tạo. Vui lòng thử lại sau.');
  }
  
  if (username.isEmpty || password.isEmpty) {
    throw Exception('Chat ID hoặc mật khẩu không được để trống');
  }
  
  // Create a completer to handle the async response
  final completer = Completer<Map<String, dynamic>>();
  _pendingResponses[username] = completer;
  
  try {
    logger.log("Attempting UDP registration for user: $username");
    
    // Register a callback for registration response
    _udpClient!.handshakeManager.registerRegisterCallback(username, (response) {
      logger.log("Received register callback response: $response");
      
      if (!_pendingResponses.containsKey(username) || 
          _pendingResponses[username]!.isCompleted) {
        logger.log("No pending request found for $username or already completed");
        return;
      }
      
      // Complete the future with the response
      _pendingResponses[username]!.complete(response);
    });
    
    // Also register error callback to catch registration failures
    _udpClient!.handshakeManager.registerErrorCallback(username, (errorResponse) {
      logger.log("Received error callback for registration: $errorResponse");
      
      if (!_pendingResponses.containsKey(username) || 
          _pendingResponses[username]!.isCompleted) {
        logger.log("No pending request found for $username or already completed");
        return;
      }
      
      // Complete the future with the error response
      _pendingResponses[username]!.complete({
        'status': 'failure',
        'message': errorResponse['message'] ?? 'Registration failed'
      });
    });
    
    // Send registration request through HandshakeManager
    final registerResult = await _udpClient!.handshakeManager.sendClientRequestWithAck(
      JsonHelper.createRequest(Constants.ACTION_REGISTER, {
        Constants.KEY_CHAT_ID: username,
        Constants.KEY_PASSWORD: password
      }),
      Constants.ACTION_REGISTER,
      Constants.FIXED_LOGIN_KEY_STRING
    );
    
    // If we got a result directly, complete with it
    if (registerResult != null) {
      if (!_pendingResponses[username]!.isCompleted) {
        _pendingResponses[username]!.complete(registerResult);
      }
    } else {
      // Fallback to command processing if direct request failed
      final registerCommand = "/register $username $password";
      logger.log("Direct request failed, trying command: $registerCommand");
      await processCommand(_udpClient!, registerCommand);
    }
    
    // Wait for the response with timeout
    Map<String, dynamic> response;
    try {
      response = await completer.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () => {
          'status': 'timeout',
          'message': 'Đăng ký hết thời gian chờ. Máy chủ không phản hồi.'
        }
      );
    } catch (e) {
      logger.log("Timeout or error getting register response: $e");
      response = {
        'status': 'error',
        'message': 'Lỗi xử lý đăng ký: $e'
      };
    }
    
    logger.log("Registration response received: $response");
    
    // Check for timeout or error
    if (response['status'] == 'timeout' || response['status'] == 'error') {
      throw Exception(response['message']);
    }
    
    // Check for failed registration
    if (response['status'] != Constants.STATUS_SUCCESS) {
      final message = response['message'] ?? 'Đăng ký thất bại';
      
      // Classify registration errors
      if (message.toLowerCase().contains('already exists') || 
          message.toLowerCase().contains('taken')) {
        throw Exception('Chat ID đã tồn tại, vui lòng chọn tên khác');
      } else {
        throw Exception('Đăng ký thất bại: $message');
      }
    }
    
    // Create User object from response
    final user = User(
      chatId: username,
      password: password,
      createdAt: DateTime.now()
    );
    
    logger.log("Registration successful for user: $username");
    return user;
    
  } catch (e) {
    logger.log("Registration error: $e");
    throw Exception(e.toString().replaceAll('Exception: ', ''));
  } finally {
    // Always remove the callbacks and pending response
    _udpClient?.handshakeManager.removeRegisterCallback(username);
    _udpClient?.handshakeManager.removeErrorCallback(username);
    _pendingResponses.remove(username);
  }
}
}
