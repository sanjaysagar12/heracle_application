import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_endpoints.dart';
import '../domain/models/workout_log_model.dart';

class WorkoutLogsApi {
  static const String _tokenKey = 'dev_auth_token';

  static Future<List<WorkoutLog>> fetchWorkoutLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    final uri = Uri.parse(workoutLogsUrl);
    final headers = <String, String>{
      'accept': '*/*',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(resp.body);
      final logsJson = (data['logs'] as List<dynamic>?) ?? <dynamic>[];
      return logsJson
          .map((e) => WorkoutLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load workout logs: ${resp.statusCode} ${resp.body}');
    }
  }
}
