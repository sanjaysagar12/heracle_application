import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Add this import for MediaType
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_endpoints.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
      throw Exception(
        'Failed to start workout: ${resp.statusCode} ${resp.body}',
      );
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
      throw Exception(
        'Failed to get workout progress: ${resp.statusCode} ${resp.body}',
      );
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
      throw Exception(
        'Failed to update exercise progress: ${resp.statusCode} ${resp.body}',
      );
    }
  }

  static Future<Map<String, dynamic>> completeWorkout(
    String logId,
    String? notes,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    final uri = Uri.parse(completeWorkoutUrl(logId));
    final headers = <String, String>{
      'accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({'notes': notes ?? ''});

    final resp = await http.post(uri, headers: headers, body: body);
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Failed to complete workout: ${resp.statusCode} ${resp.body}',
      );
    }
  }

  static Future<Map<String, dynamic>> postWorkout({
    required String logId,
    File? imageFile,
    XFile? imageXFile, // For web compatibility
    required String caption,
    required bool isPublic,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    final uri = Uri.parse(postWorkoutUrl(logId));

    // Debug: Print request details
    print('POST URL: $uri');
    print('Caption: $caption');
    print('IsPublic: $isPublic');
    print('Has image file: ${imageFile != null}');
    print('Has XFile: ${imageXFile != null}');
    print('Token exists: ${token != null}');

    final request = http.MultipartRequest('POST', uri);

    // Add headers - matches curl exactly
    request.headers.addAll({
      'accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    });

    // Add form fields - ensure exact format
    request.fields['caption'] = caption;
    request.fields['isPublic'] = isPublic
        ? 'true'
        : 'false'; // Ensure string boolean

    // Add file if provided
    if (kIsWeb && imageXFile != null) {
      // For web: use XFile
      final bytes = await imageXFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: imageXFile.name,
        contentType: MediaType(
          'image',
          imageXFile.name.split('.').last,
        ), // Add content type
      );
      request.files.add(multipartFile);
      print('Added web image file: ${imageXFile.name}');
    } else if (!kIsWeb && imageFile != null) {
      // For mobile: use File with explicit content type
      String? mimeType = _getMimeType(imageFile.path);
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      );
      request.files.add(multipartFile);
      print('Added mobile image file: ${imageFile.path}, mime: $mimeType');
    }

    // Debug: Print all fields and files
    print('Request fields: ${request.fields}');
    print('Request files count: ${request.files.length}');
    print('Request headers: ${request.headers}');

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Debug: Print response details
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('Response headers: ${response.headers}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData;
      } else {
        throw Exception(
          'Failed to post workout: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('Exception occurred: $e');
      rethrow;
    }
  }

  // Helper method to determine MIME type
  static String? _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
    }
  }
}
