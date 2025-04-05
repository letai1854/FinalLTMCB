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
  
  // Global list of users for the entire app
  static List<User> _globalUserList = [];
  
  // Static getter to access the global user list
  static List<User> get allUsers => List.unmodifiable(_globalUserList);

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
  
  // Local cache of users (for the instance)
  final List<User> _cachedUsers = [];
  
  // Getter for the cached users
  List<User> get cachedUsers => List.unmodifiable(_cachedUsers);

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
  
  // Check for pending operation
  if (_pendingResponses.containsKey(chatId) && !_pendingResponses[chatId]!.isCompleted) {
    logger.log("Aborting: Another operation already in progress for $chatId");
    throw Exception('Thao tác đang được xử lý. Vui lòng đợi.');
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
      const Duration(seconds: 3), // Increased timeout
      onTimeout: () => {
        'status': 'timeout',
        'message': 'Đăng nhập thất bại'
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
    
    // Đã bỏ đoạn code load user list ở đây như yêu cầu
    
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
    
    // Check for pending operation
    if (_pendingResponses.containsKey(username) && !_pendingResponses[username]!.isCompleted) {
      logger.log("Aborting: Another operation already in progress for $username");
      throw Exception('Thao tác đang được xử lý. Vui lòng đợi.');
    }
    
    try {
      // Clear existing callbacks first
      _udpClient?.handshakeManager.removeRegisterCallback(username);
      _udpClient?.handshakeManager.removeErrorCallback(username);
      
      // Create a completer to handle the async response
      final completer = Completer<Map<String, dynamic>>();
      _pendingResponses[username] = completer;
      
      logger.log("Attempting UDP registration for user: $username");
      
      // Register a callback for registration response
      _udpClient!.handshakeManager.registerRegisterCallback(username, (response) {
        if (!_pendingResponses.containsKey(username) || 
            _pendingResponses[username]!.isCompleted) return;
        _pendingResponses[username]!.complete(response);
      });
      
      // Also register error callback to catch registration failures
      _udpClient!.handshakeManager.registerErrorCallback(username, (errorResponse) {
        if (!_pendingResponses.containsKey(username) || 
            _pendingResponses[username]!.isCompleted) return;
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
        await _udpClient!.commandProcessor.processCommand(registerCommand);
      }
      
      // Wait for the response with timeout
      Map<String, dynamic> response = await completer.future.timeout(
        const Duration(seconds: 5), // Increased timeout
        onTimeout: () => {
          'status': 'timeout',
          'message': 'Đăng ký hết thời gian chờ. Máy chủ không phản hồi.'
        }
      );
      
      // Check for timeout or error
      if (response['status'] == 'timeout' || response['status'] == 'error') {
        throw Exception(response['message']);
      }
      
      // Check for failed registration
      if (response['status'] != Constants.STATUS_SUCCESS) {
        final message = response['message'] ?? 'Đăng ký thất bại';
        throw Exception(message.toLowerCase().contains('already exists') || 
                       message.toLowerCase().contains('taken')
                       ? 'Chat ID đã tồn tại, vui lòng chọn tên khác'
                       : 'Đăng ký thất bại: $message');
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

  // Method to load all users and store in global list
  Future<void> loadUserList() async {
    try {
      final users = await showUsers(); // Changed to camelCase
      _globalUserList = users;
      print("📋 Loaded ${users.length} users into global list");
    } catch (e) {
      print("❌ Failed to load user list: $e");
      throw e;
    }
  }

  Future<List<User>> showUsers() async {
    if (_udpClient == null) {
      throw Exception('UDP Client không được khởi tạo. Vui lòng thử lại sau.');
    }
    
    // Tạo completer để chuyển đổi callback thành Future
    final completer = Completer<List<User>>();
    
    try {
      // Đăng ký callback tạm thời để nhận danh sách người dùng
      void usersCallback(Map<String, dynamic> response) {
        try {
          if (!response.containsKey('users')) {
            completer.completeError('Không nhận được danh sách người dùng');
            return;
          }
          
          final usersList = <User>[];
          final List<dynamic> rawUsers = response['users'];
          
          for (var userData in rawUsers) {
            if (userData is Map<String, dynamic>) {
              usersList.add(User(
                chatId: userData['chatId'] ?? userData['id'],
                password: '', // Không có mật khẩu trong response
                createdAt: DateTime.now(),
              ));
            }
          }
          
          // Cập nhật cache
          _cachedUsers.clear();
          _cachedUsers.addAll(usersList);
          
          // Update global list too
          _globalUserList = List.from(usersList);
          
          // Hoàn thành Future với danh sách người dùng
          completer.complete(usersList);
        } catch (e) {
          completer.completeError('Lỗi xử lý danh sách người dùng: $e');
        }
      }
      
      // Đăng ký callback tạm thời
      _udpClient!.handshakeManager.registerUsersCallback(usersCallback);
      
      // Gửi lệnh để lấy danh sách người dùng
      await _udpClient!.commandProcessor.processCommand("/users");
      
      // Chờ phản hồi với timeout
      return await completer.future.timeout(
        const Duration(seconds: 5), // Increased timeout
        onTimeout: () {
          // Nếu timeout nhưng có dữ liệu cache, trả về cache
          if (_cachedUsers.isNotEmpty) {
            return _cachedUsers;
          }
          throw Exception('Hết thời gian chờ khi lấy danh sách người dùng');
        }
      );
    } catch (e) {
      // Nếu có lỗi nhưng có cache, trả về cache
      if (_cachedUsers.isNotEmpty) {
        return _cachedUsers;
      }
      throw Exception('Không thể lấy danh sách người dùng: $e');
    } finally {
      // Luôn xóa callback khi hoàn thành
      _udpClient?.handshakeManager.removeUsersCallback();
    }
  }

  // Clear all callbacks and reset state
 
}
