import 'package:flutter/material.dart';
import 'package:heracle/src/auth/data/auth_repository.dart';
import '../../../route.dart'; // Added import for AppRoutes constants

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev Auth'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // New: Dev Auth button — navigates directly to home without signing in
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
              },
              child: const Text('Dev Auth'),
            ),

            const SizedBox(height: 12),

            // Existing Signin button (kept)
            TextButton(
              onPressed: () async {
                try {
                  await AuthRepository().signInWithGoogle();
                  Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
                } catch (e) {
                  print("Login failed: $e");
                }
              },
              child: const Text('Signin'),
            ),
          ],
        ),
      ),
    );
  }
}
