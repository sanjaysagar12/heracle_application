import 'package:flutter/foundation.dart';
import '../data/profile_repository.dart';

/// UserProfileProvider manages the current user's profile state globally.
///
/// This eliminates duplicate API calls for profile data across screens
/// (home_page, workout_page, profile_page all fetch the same profile).
class UserProfileProvider extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  Profile? _profile;
  bool _isLoading = false;
  String? _error;

  UserProfileProvider({ProfileRepository? profileRepository})
    : _profileRepository = profileRepository ?? ProfileRepository();

  // Getters
  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProfile => _profile != null;

  // Convenience getters
  String get name => _profile?.name ?? '';
  String get username => _profile?.username ?? '';
  int get age => _profile?.age ?? 0;
  String get profileImageUrl => _profile?.profileImageUrl ?? '';
  bool get hasStory => _profile?.hasStory ?? false;

  /// Load the current user's profile
  Future<void> loadProfile() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _profileRepository.getProfile();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh profile (force reload)
  Future<void> refreshProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _profileRepository.getProfile();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update profile locally (after onboarding/edit)
  void updateProfile(Profile newProfile) {
    _profile = newProfile;
    notifyListeners();
  }

  /// Update hasStory status
  void updateHasStory(bool hasStory) {
    if (_profile != null) {
      _profile = Profile(
        name: _profile!.name,
        username: _profile!.username,
        age: _profile!.age,
        profileImageUrl: _profile!.profileImageUrl,
        hasStory: hasStory,
      );
      notifyListeners();
    }
  }

  /// Clear profile (on logout)
  void clear() {
    _profile = null;
    _error = null;
    notifyListeners();
  }

  /// Clear any error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
