import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:heracle/core/storage/local_storage.dart';
import 'package:heracle/core/theme/app_theme.dart';
import 'package:heracle/src/auth/providers/auth_provider.dart';
import 'package:heracle/src/home/providers/user_profile_provider.dart';
import 'package:heracle/src/home/providers/feed_provider.dart';
import 'route.dart';
import 'src/splash_screen.dart';
import 'core/services/notification_service.dart';
import 'core/services/deep_link_service.dart';

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

  // Initialize DeepLinkService with the GlobalKey
  DeepLinkService().init(navigatorKey);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'Heracle',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
