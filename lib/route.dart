import 'package:flutter/material.dart';
import 'src/home/presentation/home_page.dart';
import 'src/auth/presentation/dev_auth_screen.dart'; // added import

class AppRoutes {
  static const String home = '/';
  static const String second = '/second';
  static const String devAuth = '/dev-auth'; // added route constant

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case second:
        return MaterialPageRoute(builder: (_) => const SecondPage());
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

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Page'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back'),
        ),
      ),
    );
  }
}
