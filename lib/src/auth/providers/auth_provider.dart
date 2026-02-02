import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/storage/local_storage.dart';
import '../data/auth_repository.dart';
import '../../workout/data/session_repository.dart';

/// Authentication state for the app
enum AuthStatus {
  unknown, // Initial state, checking auth
  authenticated,
  unauthenticated,
}

/// AuthProvider manages global authentication state.
///
/// Use this provider to:
/// - Check if user is authenticated
/// - Sign in/out
/// - Access current user info from token
class AuthProvider extends ChangeNotifier {
  final LocalStorageService _storage;
  final AuthRepository _authRepository;
  final SessionRepository _sessionRepository;

  AuthStatus _status = AuthStatus.unknown;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _userFromToken;

  AuthProvider({
    LocalStorageService? storage,
    AuthRepository? authRepository,
    SessionRepository? sessionRepository,
  }) : _storage = storage ?? LocalStorageService(),
       _authRepository = authRepository ?? AuthRepository(),
       _sessionRepository = sessionRepository ?? SessionRepository();

  // Getters
  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get error => _error;
  Map<String, dynamic>? get userFromToken => _userFromToken;

  /// Initialize auth state by checking stored token
  Future<void> checkAuthStatus() async {
    try {
      final token = _storage.getAuthToken();

      if (token == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      if (JwtDecoder.isExpired(token)) {
        await _storage.clearAuthToken();
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      // Decode token to get user info
      _userFromToken = JwtDecoder.decode(token);
      _status = AuthStatus.authenticated;
      notifyListeners();

      // Refresh FCM token on app start if authenticated
      _registerFcmToken();
    } catch (e) {
      debugPrint('AuthProvider: Error checking auth status: $e');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.signInWithGoogle();

      // Refresh token info
      final token = _storage.getAuthToken();
      if (token != null) {
        _userFromToken = JwtDecoder.decode(token);
      }

      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();

      // Register FCM token
      _registerFcmToken();

      // Sync sessions from server
      await _sessionRepository.syncSessionsOnLogin();

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Dev auth for testing
  Future<bool> devAuth(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.devAuth(email);

      final token = _storage.getAuthToken();
      if (token != null) {
        _userFromToken = JwtDecoder.decode(token);
      }

      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();

      // Register FCM token
      _registerFcmToken();

      // Sync sessions from server
      await _sessionRepository.syncSessionsOnLogin();

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _storage.clearAuthToken();
      _userFromToken = null;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Register FCM token with backend
  Future<void> _registerFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print('Registering FCM token: $token');
        await _authRepository.sendFcmToken(token);
      }
    } catch (e) {
      print('Failed to register FCM token: $e');
      // Non-blocking error
    }
  }

  /// Clear any error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
