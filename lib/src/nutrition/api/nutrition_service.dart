import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/dio_client.dart';
import '../data/food_item_model.dart';
import '../data/nutrition_history_model.dart'; // Added

class NutritionApiService {
  /// Search for foods matching the query
  Future<List<FoodItem>> searchFoods(String query) async {
    try {
      final response = await DioClient().dio.get(
        '/api/nutrition/foods',
        queryParameters: {'query': query},
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => FoodItem.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      // Return empty list on error to allow manual entry without interruption
      return [];
    }
  }

  /// Save meal log matching new schema with MultipartRequest
  Future<Map<String, dynamic>> saveMeal(FormData formData) async {
    try {
      debugPrint(
        "🍽️ [API] saveMeal - Sending request to /api/nutrition/log/bulk",
      );
      debugPrint("🍽️ [API] saveMeal - FormData fields: ${formData.fields}");

      final response = await DioClient().dio.post(
        '/api/nutrition/log/bulk',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      debugPrint(
        "🍽️ [API] saveMeal - Response status: ${response.statusCode}",
      );
      debugPrint("🍽️ [API] saveMeal - Response data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to save log: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("🍽️ [API] saveMeal - ERROR: $e");
      throw Exception('Failed to save log: $e');
    }
  }

  /// Post meal to feed using session ID
  Future<void> postMeal(String sessionId) async {
    try {
      debugPrint(
        "🍽️ [API] postMeal - Sending request to /api/post/meal with sessionId: $sessionId",
      );

      final response = await DioClient().dio.post(
        '/api/post/meal',
        data: {'sessionId': sessionId},
      );

      debugPrint(
        "🍽️ [API] postMeal - Response status: ${response.statusCode}",
      );
      debugPrint("🍽️ [API] postMeal - Response data: ${response.data}");

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to post meal: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("🍽️ [API] postMeal - ERROR: $e");
      throw Exception('Failed to post meal: $e');
    }
  }

  /// Update meal caption
  Future<void> updateMealCaption(String sessionId, String caption) async {
    try {
      final response = await DioClient().dio.patch(
        '/api/post/meal/session/$sessionId/caption',
        data: {'caption': caption},
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to update caption: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update caption: $e');
    }
  }

  /// Analyze food from image
  Future<Map<String, dynamic>> analyzeFood(
    File image,
    String description,
  ) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          image.path,
          filename: 'image.jpg',
        ),
        'description': description,
      });

      final response = await DioClient().dio.post(
        '/api/calai/analyze',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to analyze food: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to analyze food: $e');
    }
  }

  /// Get nutrition sessions/history
  Future<List<NutritionHistoryResponse>> getNutritionHistory() async {
    try {
      final response = await DioClient().dio.get('/api/nutrition/sessions');

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => NutritionHistoryResponse.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Failed to load nutrition history: $e');
      return [];
    }
  }

  /// Delete a nutrition session (meal post)
  /// Endpoint: DELETE /api/nutrition/sessions/:id
  /// Returns { deleted: true, id: "<session_id>" } on success
  Future<bool> deleteSession(String sessionId) async {
    try {
      debugPrint(
        "🍽️ [API] deleteSession - Sending DELETE request for sessionId: $sessionId",
      );

      final response = await DioClient().dio.delete(
        '/api/nutrition/sessions/$sessionId',
      );

      debugPrint(
        "🍽️ [API] deleteSession - Response status: ${response.statusCode}",
      );
      debugPrint("🍽️ [API] deleteSession - Response data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Check if response contains deleted: true
        if (response.data != null && response.data['deleted'] == true) {
          return true;
        }
        return true; // Consider success if status is OK
      } else {
        throw Exception('Failed to delete session: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("🍽️ [API] deleteSession - ERROR: $e");
      throw Exception('Failed to delete session: $e');
    }
  }
}
