import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:heracle/core/network/dio_client.dart';
import 'package:heracle/core/helper/constants.dart';
import 'package:dio/dio.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Dio _dio = DioClient().dio;

  Future<String> signInWithGoogle() async {
    try {
      // Initialize GoogleSignIn (required in version 7.x)
      print("Initializing Google Sign In...");
      await GoogleSignIn.instance.initialize();
      
      // Trigger the authentication flow
      print("Starting Google Sign In...");
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();

      if (googleUser == null) {
        throw Exception('Google Sign In aborted by user');
      }

      print("Google User: ${googleUser.email}");

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print("Got Google Auth tokens");
      print("ID Token: ${googleAuth.idToken != null ? 'Present' : 'Missing'}");

      // Create a new credential (google_sign_in 7.x only provides idToken)
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      print("Signing in to Firebase...");

      // Once signed in, return the UserCredential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        print('-----------------------------------------');
        print('Successfully signed in with Google!');
        print('UID: ${user.uid}');
        print('Email: ${user.email}');
        print('DisplayName: ${user.displayName}');
        print('PhotoURL: ${user.photoURL}');
        print('-----------------------------------------');
        
        // Return the ID token
        final String? idToken = await user.getIdToken();
        if (idToken == null) throw Exception("Failed to retrieve ID Token");
        
        // Verify with backend
        print("Verifying with backend...");
        final backendToken = await _verifyWithBackend(idToken);
        print("Backend verification successful!");
        return backendToken;
      } else {
        throw Exception('Firebase Sign In failed: User is null');
      }
    } catch (e) {
      print("Error in signInWithGoogle: $e");
      rethrow;
    }
  }

  Future<String> _verifyWithBackend(String idToken) async {
    print("Verifying with backend...");
    print("ID Token: $idToken");
    try {
      final res = await _dio.post(
        "/api/auth/google/token",
        data: {"idToken": idToken},
      );
      
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (res.data['token'] != null) {
          return res.data['token'];
        }
        throw Exception("Response missing 'token' field");
      } else {
        throw Exception("Backend responded with status: ${res.statusCode}");
      }
    } on DioException catch (e) {
      print("Dio Error verifying with backend: ${e.message}");
      if (e.response != null) {
        print("Backend response data: ${e.response?.data}");
        throw Exception("Server error: ${e.response?.data}");
      }
      rethrow;
    } catch (e) {
      print("Error verifying with backend: $e");
      rethrow;
    }
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

