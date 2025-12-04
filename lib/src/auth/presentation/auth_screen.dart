import 'package:flutter/material.dart';
import 'package:heracle/src/auth/data/auth_repository.dart';
import '../../../route.dart'; // Added import for AppRoutes constants
import 'package:dio/dio.dart';
import 'package:heracle/core/storage/local_storage.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;

  Future<void> _handleDevAuth() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await AuthRepository().devAuth('sanjaysagar.main@gmail.com');
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dev Auth Failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
            // Dev Auth button
            _isLoading
                ? const CircularProgressIndicator()
                : TextButton(
                    onPressed: _handleDevAuth,
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
