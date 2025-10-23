import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_endpoints.dart'; // updated import to new filename/path

class TokenStorage {
  static const String _key = 'dev_auth_token';

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class DevAuthApi {
  // Sends POST to /api/auth/dev/token with {"email": "<email>"} and returns token string.
  static Future<String> getToken(String email) async {
    // use shared endpoint constant
    final uri = Uri.parse(devTokenUrl);
    final resp = await http.post(
      uri,
      headers: {
        'accept': '*/*',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email}),
    );

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(resp.body);
      final token = data['token'] as String?;
      if (token != null && token.isNotEmpty) {
        await TokenStorage.setToken(token);
        return token;
      } else {
        throw Exception('token missing in response');
      }
    } else {
      throw Exception('Failed to get token: ${resp.statusCode} ${resp.body}');
    }
  }
}
