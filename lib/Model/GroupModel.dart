class GroupModel {
  String id;
  String name;
  String message;
  String avatar;
  bool isOnline;
  bool isGroup;
  List<String> members;

  // Constructor
  GroupModel({
    required this.id,
    required this.name,
    required this.message,
    this.avatar = 'assets/logoS.jpg',
    this.isOnline = true,
    this.isGroup = true,
    required this.members,
  });

  // Create from Map (for JSON deserialization)
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      message: map['message'] ?? '',
      avatar: map['avatar'] ?? 'assets/logoS.jpg',
      isOnline: map['isOnline'] ?? true,
      isGroup: map['isGroup'] ?? true,
      members: List<String>.from(map['members'] ?? []),
    );
  }

  // Convert to Map (for JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'message': message,
      'avatar': avatar,
      'isOnline': isOnline,
      'isGroup': isGroup,
      'members': members,
    };
  }
}
