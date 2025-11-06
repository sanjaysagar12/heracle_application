import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleConfig {
  static const REFRESH_TOKEN_KEY = 'refresh_token';
  static const BACKEND_TOKEN_KEY = 'backend_token';

  static String get issuer => dotenv.env['GOOGLE_ISSUER'] ?? 'https://accounts.google.com';
  static String get discoveryUrl => "$issuer/.well-known/openid-configuration";

  static String get clientId {
    if (Platform.isAndroid) {
      return dotenv.env['GOOGLE_CLIENT_ID_ANDROID'] ?? '';
    } else if (Platform.isIOS) {
      return dotenv.env['GOOGLE_CLIENT_ID_IOS'] ?? '';
    }
    return '';
  }

  static String get redirectUri {
    if (Platform.isAndroid) {
      return dotenv.env['GOOGLE_REDIRECT_URI_ANDROID'] ?? '';
    } else if (Platform.isIOS) {
      return dotenv.env['GOOGLE_REDIRECT_URI_IOS'] ?? '';
    }
    return '';
  }

  static String get serverClientId => dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '';
}
