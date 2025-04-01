import 'package:flutter/foundation.dart';

enum UserRole { customer, admin }

class User {
  final int id;
  final String email;
  final String fullName;
  final String? password;
  final String? address;
  final UserRole role;
  final DateTime createdDate;
  final bool status;
  final int customerPoints;
  final String? avatar;
  final int? chatId;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.password,
    this.address,
    this.role = UserRole.customer,
    required this.createdDate,
    this.status = true,
    this.customerPoints = 0,
    this.avatar,
    this.chatId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print('Parsing JSON in fromJson: $json'); // Debug print

    try {
      return User(
        id: json['id'] as int? ?? 0,
        email: json['email'] as String? ?? '',
        fullName: json['fullName'] as String? ??
            '', // Changed from full_name to fullName
        password: json['password'] as String?,
        address: json['address'] as String?,
        role: UserRole.values.firstWhere(
          (e) =>
              e.toString().split('.').last.toLowerCase() ==
              (json['role'] as String?)?.toLowerCase(),
          orElse: () => UserRole.customer,
        ),
        createdDate: DateTime.parse(
            json['createdDate'] ?? DateTime.now().toIso8601String()),
        status: json['status'] as bool? ?? true,
        customerPoints: json['customerPoints'] as int? ?? 0,
        avatar: json['avatar'] as String?,
        chatId: json['chatId'] as int?,
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
      'id': id,
      'email': email,
      'full_name': fullName, // Use snake_case
      'password': password,
      'address': address,
      'role': role.toString().split('.').last.toLowerCase(),
      'created_date': createdDate.toIso8601String(), // Use snake_case
      'status': status,
      'customer_points': customerPoints, // Use snake_case
      'avatar': avatar,
      'chat_id': chatId, // Use snake_case
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? fullName,
    String? password,
    String? address,
    UserRole? role,
    DateTime? createdDate,
    bool? status,
    int? customerPoints,
    String? avatar,
    int? chatId,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      password: password ?? this.password,
      address: address ?? this.address,
      role: role ?? this.role,
      createdDate: createdDate ?? this.createdDate,
      status: status ?? this.status,
      customerPoints: customerPoints ?? this.customerPoints,
      avatar: avatar ?? this.avatar,
      chatId: chatId ?? this.chatId,
    );
  }

  @override
  @override
  String toString() {
    return 'User('
        'id: $id, '
        'email: $email, '
        'fullName: $fullName, '
        'address: $address, '
        'role: $role, '
        'customerPoints: $customerPoints, '
        'avatar: $avatar, '
        'chatId: $chatId'
        ')';
  }
}
