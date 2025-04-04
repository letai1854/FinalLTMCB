import 'package:flutter/foundation.dart';

class User {
  final String chatId;     // PK, NOT NULL
  final String? password;  // NOT NULL (nhưng nullable trong model để bảo mật)
  final DateTime createdAt; // Timestamp, mặc định current_timestamp()

  User({
    required this.chatId,
    this.password,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print('Parsing JSON in fromJson: $json');

    try {
      return User(
        chatId: json['chatId'] as String? ?? '',
        password: json['password'] as String?,
        createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      );
    } catch (e, stackTrace) {
      print('Error parsing JSON: $e');
      print('Stack trace: $stackTrace');
      print('Problematic JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'password': password,
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? chatId,
    String? password,
    DateTime? createdAt,
  }) {
    return User(
      chatId: chatId ?? this.chatId,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'User(chatId: $chatId, createdAt: $createdAt)';
  }
}
