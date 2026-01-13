import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;

  late SharedPreferences _prefs;

  LocalStorageService._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  static const String _onboardingKey = 'has_seen_onboarding';

  Future<void> saveAuthToken(String token) async {
    await _prefs.setString('dev_auth_token', token);
  }

  String? getAuthToken() => _prefs.getString('dev_auth_token');

  Future<void> clearAuthToken() async {
    await _prefs.remove('dev_auth_token');
  }

  bool isFirstLaunch() {
    return !(_prefs.getBool(_onboardingKey) ?? false);
  }

  Future<void> setOnboardingSeen() async {
    await _prefs.setBool(_onboardingKey, true);
  }
  // Future<void> setFirstLaunch(bool value) async {
  //   await _prefs.setBool(_onboardingKey, value);
  // }
}