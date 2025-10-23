import 'package:flutter/material.dart';
import '../api/dev_auth_api.dart';
import '../../../route.dart'; // Added import for AppRoutes constants

class DevAuthScreen extends StatefulWidget {
  const DevAuthScreen({super.key});

  @override
  State<DevAuthScreen> createState() => _DevAuthScreenState();
}

class _DevAuthScreenState extends State<DevAuthScreen> {
  final TextEditingController _emailController =
      TextEditingController(text: 'sanjaysagar@gmail.com');
  bool _loading = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadStoredToken();
  }

  Future<void> _loadStoredToken() async {
    final stored = await TokenStorage.getToken();
    if (stored != null && mounted) {
      setState(() {
        _token = stored;
      });
    }
  }

  Future<void> _requestToken() async {
    setState(() => _loading = true);
    try {
      final token = await DevAuthApi.getToken(_emailController.text.trim());
      setState(() {
        _token = token;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token received and stored')),
      );

      // Navigate to home page after successful token retrieval
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev Auth'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Remove back button if this is the initial screen
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Request a development token from the backend. The token will be stored for further use.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _requestToken,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Get Token'),
              ),
            ),
            const SizedBox(height: 16),
            if (_token != null) ...[
              // Simplified token display - removed copy functionality
              Text(
                'Token received:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SelectableText(
                _token!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 3,
              ),
            ],
            const Spacer(),
            Align(
              alignment: Alignment.bottomCenter,
              child: TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
                child: const Text('Continue to App'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
