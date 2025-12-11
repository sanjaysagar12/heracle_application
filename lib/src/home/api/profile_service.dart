import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class ProfileService {
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await DioClient().dio.get('/api/user/my-profile');
      return response.data;
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }
}
