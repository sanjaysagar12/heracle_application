import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_endpoints.dart';
import '../domain/models/session_model.dart';
import '../domain/models/add_exercise_request.dart';

class ExerciseApi {
  static const String _tokenKey = 'dev_auth_token';

  static Future<List<Exercise>> fetchExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    final uri = Uri.parse(exercisesUrl);
    final headers = <String, String>{
      'accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(resp.body);
      final exercisesJson = (data['exercises'] as List<dynamic>?) ?? <dynamic>[];
      return exercisesJson
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load exercises: ${resp.statusCode} ${resp.body}');
    }
  }

  static Future<void> addExerciseToSession(String sessionId, AddExerciseRequest request) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    final uri = Uri.parse(sessionExercisesUrl(sessionId));
    final headers = <String, String>{
      'accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final resp = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(request.toJson()),
    );

    if (resp.statusCode != 201) {
      throw Exception('Failed to add exercise to session: ${resp.statusCode} ${resp.body}');
    }
  }
}
