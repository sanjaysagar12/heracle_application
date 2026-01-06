import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../data/food_item_model.dart';

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
  /// Save meal log matching new schema
  /// Save meal log matching new schema
  Future<Map<String, dynamic>> saveMeal(Map<String, dynamic> payload) async {
    try {
      final response = await DioClient().dio.post(
        '/api/nutrition/log/bulk',
        data: payload,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to save log: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to save log: $e');
    }
  }

  /// Post meal to feed using session ID
  Future<void> postMeal(String sessionId) async {
    try {
      final response = await DioClient().dio.post(
        '/api/post/meal',
        data: {'sessionId': sessionId},
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to post meal: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to post meal: $e');
    }
  }
}
