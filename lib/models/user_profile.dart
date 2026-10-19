class UserProfile {
  final String id;
  final String? username;
  final String displayName;
  final String? avatarUrl;
  final String email;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    this.username,
    required this.displayName,
    this.avatarUrl,
    required this.email,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, {String email = ''}) {
    return UserProfile(
      id: map['id']?.toString() ?? '',
      username: map['username']?.toString(),
      displayName: map['display_name']?.toString() ??
          map['full_name']?.toString() ??
          'Soundifly Member',
      avatarUrl: map['avatar_url']?.toString(),
      email: email,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (username != null) 'username': username,
      'display_name': displayName,
      'full_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
