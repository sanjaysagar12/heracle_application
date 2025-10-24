import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_endpoints.dart';

class WorkoutProgressApi {
  static const String _tokenKey = 'dev_auth_token';

  static Future<Map<String, dynamic>> startWorkout(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    final uri = Uri.parse(workoutStartUrl(sessionId));
    final headers = <String, String>{
      'accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final resp = await http.post(uri, headers: headers, body: '');
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to start workout: ${resp.statusCode} ${resp.body}');
    }
  }

  static Future<Map<String, dynamic>> getWorkoutProgress(String logId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    final uri = Uri.parse(workoutProgressUrl(logId));
    final headers = <String, String>{
      'accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get workout progress: ${resp.statusCode} ${resp.body}');
    }
  }

  static Future<Map<String, dynamic>> updateExerciseProgress(
    String logId,
    String exerciseId,
    Map<String, dynamic> updateData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    final uri = Uri.parse(updateExerciseProgressUrl(logId, exerciseId));
    final headers = <String, String>{
      'accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final resp = await http.put(
      uri,
      headers: headers,
      body: jsonEncode(updateData),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update exercise progress: ${resp.statusCode} ${resp.body}');
    }
  }
}
