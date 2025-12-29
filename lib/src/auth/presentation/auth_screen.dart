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
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: 'sanjaysagar.main@gmail.com');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _showDevAuthDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Dev Authentication'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Enter specific email for testing:'),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Dev Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Login'),
              onPressed: () {
                Navigator.of(context).pop();
                _performDevAuth();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDevAuth() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        throw Exception('Email cannot be empty');
      }
      await AuthRepository().devAuth(email);
      
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dev Auth button
              _isLoading
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: _showDevAuthDialog,
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
                  }
                },
                child: const Text('Signin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// End of file
