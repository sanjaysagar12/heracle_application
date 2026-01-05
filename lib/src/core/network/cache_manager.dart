import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  Future<void> cacheData(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    if (data == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, jsonEncode(data));
    }
  }

  Future<dynamic> getCachedData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedString = prefs.getString(key);
    if (cachedString != null) {
      return jsonDecode(cachedString);
    }
    return null;
  }

  Future<void> clearCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
