class UserSuggestion {
  final String id;
  final String username;
  final String name;
  final String? avatarUrl;
  final List<UserSuggestionFollowedBy> followedBy;

  UserSuggestion({
    required this.id,
    required this.username,
    required this.name,
    this.avatarUrl,
    this.followedBy = const [],
  });

  factory UserSuggestion.fromJson(Map<String, dynamic> json) {
    return UserSuggestion(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      followedBy: (json['followedBy'] as List? ?? [])
          .map((e) => UserSuggestionFollowedBy.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UserSuggestionFollowedBy {
  final String id;
  final String username;
  final String name;
  final String? avatarUrl;

  UserSuggestionFollowedBy({
    required this.id,
    required this.username,
    required this.name,
    this.avatarUrl,
  });

  factory UserSuggestionFollowedBy.fromJson(Map<String, dynamic> json) {
    return UserSuggestionFollowedBy(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
