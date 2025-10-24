import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_endpoints.dart';
import '../domain/models/session_model.dart';

class SessionApi {
  // SharedPreferences key used by dev auth token storage
  static const String _tokenKey = 'dev_auth_token';

  static Future<List<WorkoutSession>> fetchSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    final uri = Uri.parse(sessionsUrl);
    final headers = <String, String>{
      'accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(resp.body);
      final sessionsJson = (data['sessions'] as List<dynamic>?) ?? <dynamic>[];
      return sessionsJson
          .map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load sessions: ${resp.statusCode} ${resp.body}');
    }
  }

  static Future<void> createSession(Map<String, dynamic> sessionData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    final uri = Uri.parse(sessionsUrl);
    final headers = <String, String>{
      'accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final resp = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(sessionData),
    );

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Failed to create session: ${resp.statusCode} ${resp.body}');
    }
  }
}
