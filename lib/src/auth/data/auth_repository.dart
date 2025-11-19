import 'package:heracle/core/storage/local_storage.dart';
import 'package:heracle/src/auth/api/auth_service.dart';

class AuthRepository {
  static final AuthRepository _instance = AuthRepository._internal(AuthService());
  factory AuthRepository() => _instance;

  final AuthService _authService;
  AuthRepository._internal(this._authService);


  Future<void> signInWithGoogle() async {
    final jwt = await _authService.signInWithGoogle();
    LocalStorageService().saveAuthToken(jwt);
  }
}