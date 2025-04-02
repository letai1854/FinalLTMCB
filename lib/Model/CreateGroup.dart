class CreateGroup {
  String name;
  String message;
  String avatar;
  bool isOnline;
  String id;
  bool isGroup;
  List<String> members;

  // Constructor
  CreateGroup({
    required this.name,
    required this.message,
    this.avatar = 'assets/logoS.jpg',
    this.isOnline = true,
    required this.id,
    this.isGroup = true,
    required this.members,
  });

  // Create from Map
  factory CreateGroup.fromMap(Map<String, dynamic> map) {
    return CreateGroup(
      name: map['name'] ?? '',
      message: map['message'] ?? '',
      avatar: map['avatar'] ?? 'assets/logoS.jpg',
      isOnline: map['isOnline'] ?? true,
      id: map['id'] ?? '',
      isGroup: map['isGroup'] ?? true,
      members: List<String>.from(map['members'] ?? []),
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'message': message,
      'avatar': avatar,
      'isOnline': isOnline,
      'id': id,
      'isGroup': isGroup,
      'members': members,
    };
  }
}
