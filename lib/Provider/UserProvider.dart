import 'package:finalltmcb/Model/User_model.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:universal_html/html.dart' as html;

class UserProvider {
  static final UserProvider _instance = UserProvider._internal();
  static const String USER_KEY = 'user_session';
  User? _currentUser;

  factory UserProvider() {
    return _instance;
  }

  UserProvider._internal();

  User? get currentUser => _currentUser;

  // Load user session based on platform
  Future<void> loadUserSession() async {
    if (kIsWeb) {
      // Web platform uses localStorage
      final userStr = html.window.localStorage[USER_KEY];
      if (userStr != null) {
        _currentUser = User.fromJson(json.decode(userStr));
      }
    } else {
      // Android and Desktop use SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(USER_KEY);
      if (userStr != null) {
        _currentUser = User.fromJson(json.decode(userStr));
      }
    }
  }

  // Save user session based on platform
  Future<void> setUser(User user) async {
    _currentUser = user;
    final userStr = json.encode(user.toJson());

    if (kIsWeb) {
      // Web platform
      html.window.localStorage[USER_KEY] = userStr;
    } else {
      // Android and Desktop
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(USER_KEY, userStr);
    }
  }

  // Clear user session based on platform
  Future<void> clearUser() async {
    _currentUser = null;

    if (kIsWeb) {
      html.window.localStorage.remove(USER_KEY);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(USER_KEY);
    }
  }

  bool get isLoggedIn => _currentUser != null;
}
