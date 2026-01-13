import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:heracle/core/storage/local_storage.dart';
import 'package:heracle/core/theme/app_theme.dart';
import 'route.dart';
import 'src/splash_screen.dart'; // added import for route generator
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Dotenv load error: $e');
    // Continue without .env - use fallback values
  }

  try {
    await LocalStorageService().init();
  } catch (e) {
    debugPrint('LocalStorage init error: $e');
  }

  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('NotificationService init error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heracle',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
