import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleConfig {
  static const REFRESH_TOKEN_KEY = 'refresh_token';
  static const BACKEND_TOKEN_KEY = 'backend_token';

  static String get issuer => dotenv.env['GOOGLE_ISSUER'] ?? 'https://accounts.google.com';
  static String get discoveryUrl => "$issuer/.well-known/openid-configuration";

  // These are now handled by google-services.json mostly, but keeping safe getters
  static String get clientId => ''; 
  static String get redirectUri => '';
  static String get serverClientId => dotenv.env['WEB_CLIENT_ID'] ?? '';
}
