import 'package:flutter/material.dart';
import 'package:heracle/src/splash_screen.dart';
import 'src/home/presentation/home_page.dart';
import 'src/auth/presentation/dev_auth_screen.dart';
import 'src/workout/presentation/session_page.dart';
import 'src/workout/presentation/workout_logs_page.dart';

class AppRoutes {
  static const String home = '/home';
  static const String auth = '/auth';
  static const String session = '/session';
  static const String workoutLogs = '/workout-logs'; // added route constant

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case auth:
        return MaterialPageRoute(builder: (_) => const DevAuthScreen());
      case session:
        return MaterialPageRoute(builder: (_) => const SessionPage());
      case workoutLogs:
        return MaterialPageRoute(
          builder: (_) => const WorkoutLogsPage(),
        ); 
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
