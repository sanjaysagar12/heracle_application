import '../api/profile_service.dart';

class Profile {
  final String name;
  final String username;
  final int age;
  final String profileImageUrl;
  final bool hasStory;

  Profile({
    required this.name,
    required this.username,
    required this.age,
    required this.profileImageUrl,
    this.hasStory = false,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      profileImageUrl: json['profileImageUrl'] as String? ?? '',
      hasStory: json['hasStory'] as bool? ?? false,
    );
  }
}

class ProfileRepository {
  final ProfileService _profileService;

  ProfileRepository({ProfileService? profileService})
      : _profileService = profileService ?? ProfileService();

  Future<Profile> getProfile() async {
    try {
      final data = await _profileService.getProfile();
      return Profile.fromJson(data);
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }
}
