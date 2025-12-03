import 'package:google_sign_in/google_sign_in.dart';
import 'package:heracle/core/network/dio_client.dart';
import 'package:heracle/core/helper/constants.dart';
import 'package:dio/dio.dart';

class AuthService {
  final Dio _dio = DioClient().dio;

  Future<String> _getGoogleIdToken() async {
    final googleSignIn = GoogleSignIn.instance;

    await googleSignIn.initialize(
      clientId: GoogleConfig.clientId,
      serverClientId: GoogleConfig.serverClientId,
    );

    final account = await googleSignIn.authenticate();

    final auth = await account.authentication;
    final idToken = auth.idToken;
    return idToken!;
  }

  Future<String> _verifyWithBackend(String idToken) async {
    try {
      final res = await _dio.post(
        "/api/auth/google/token",
        data: {"idToken": idToken},
      );
      if (res.statusCode == 201 && res.data['token'] != null) {
        return res.data['token'];
      } else {
        throw Exception("Unexpected response from backend");
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception("Connection timed out. Check your network.");
      } else if (e.response != null) {
        throw Exception("Server error: ${e.response?.data}");
      } else {
        throw Exception("Network error: ${e.message}");
      }
    }
  }

  Future<String> signInWithGoogle() async {
    final idToken = await _getGoogleIdToken();
    final jwt = await _verifyWithBackend(idToken);
    return jwt;
  }

  Future<String> devAuth(String email) async {
    try {
      final res = await _dio.post(
        "/api/auth/dev/token",
        data: {"email": email},
      );
      if ((res.statusCode == 200 || res.statusCode == 201) && res.data['token'] != null) {
        return res.data['token'];
      } else {
        throw Exception("Unexpected response from backend");
      }
    } catch (e) {
      print("Dev Auth failed ($e). Using mock token for testing.");
      // Return a dummy JWT token (header.payload.signature)
      // Payload: {"sub":"1234567890","name":"Dev User","iat":1516239022}
      return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkRldiBVc2VyIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c";
    }
  }
}
