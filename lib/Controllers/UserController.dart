import 'dart:convert';
import 'dart:math';
import 'package:finalltmcb/Model/User_model.dart';
import 'package:finalltmcb/Provider/UserProvider.dart';
import 'package:finalltmcb/constants/constants.dart';
import 'package:http/http.dart' as http;

class UserController {
  final String _baseEndpoint = '$baseUrl/users';
  int generateChatId() {
    return Random().nextInt(25) + 1; // Returns 1-25
  }

  // Đăng ký
  Future<User> register(Map<String, dynamic> userData) async {
    try {
      final chatId = generateChatId();

      final requestData = {
        'email': userData['email'],
        'fullName': userData['full_name'],
        'password': userData['password'],
        'address': userData['address'],
        'role': 'customer',
        'status': true,
        'customerPoints': 0,
        'chatId': chatId,
        'createdDate': DateTime.now().toIso8601String()
      };

      final response = await http.post(
        Uri.parse('$_baseEndpoint/register'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json'
        },
        body: json.encode(requestData),
      );

      if (response.statusCode == 201) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final responseData = json.decode(decodedBody);
        final user = User.fromJson(responseData);
        // UserProvider().setUser(user);
        return user;
      } else if (response.statusCode == 409) {
        throw Exception('Email đã tồn tại');
      } else {
        final errorMessage = utf8.decode(response.bodyBytes);
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow; // Propagate the error with the original message
    }
  }

  Future<User> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseEndpoint/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        final user = User.fromJson(responseData);

        // Store user in provider
        UserProvider().setUser(user);
        if (UserProvider().currentUser != null) {
          print('User: ${UserProvider().currentUser!.fullName}');
        }
        return user;
      } else if (response.statusCode == 401) {
        throw Exception('Email hoặc mật khẩu không đúng');
      } else {
        throw Exception('Đăng nhập thất bại');
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  // Cập nhật thông tin user
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
//user
