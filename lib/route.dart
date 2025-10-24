import 'package:flutter/material.dart';
import 'src/home/presentation/home_page.dart';
import 'src/auth/presentation/dev_auth_screen.dart'; 
import 'src/workout/presentation/session_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String session = '/session';
  static const String devAuth = '/dev-auth'; // added route constant

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case session:
        return MaterialPageRoute(builder: (_) => const SessionPage());
      case devAuth:
        return MaterialPageRoute(builder: (_) => const DevAuthScreen()); // added case
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: const Center(child: Text('Page not found')),
          ),
        );
    }
  }
}

