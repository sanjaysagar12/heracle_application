import '../api/profile_service.dart';

class Profile {
  final String name;
  final int age;
  final String profileImageUrl;

  Profile({
    required this.name,
    required this.age,
    required this.profileImageUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['name'] as String,
      age: json['age'] as int,
      profileImageUrl: json['profileImageUrl'] as String,
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
