import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_endpoints.dart';
import '../domain/models/workout_post_model.dart';

class WorkoutPostsApi {
  static const String _tokenKey = 'dev_auth_token';

  static Future<List<WorkoutPost>> fetchWorkoutPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    final uri = Uri.parse(workoutPostsUrl);
    final headers = <String, String>{
      'accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(resp.body);
      final postsJson = (data['posts'] as List<dynamic>?) ?? <dynamic>[];
      return postsJson
          .map((e) => WorkoutPost.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load workout posts: ${resp.statusCode} ${resp.body}');
    }
  }

  static Future<Map<String, String>> getImageHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    return {
      'accept': '*/*',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}
