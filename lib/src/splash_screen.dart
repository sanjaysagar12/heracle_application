import 'package:flutter/material.dart';
import 'package:heracle/route.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:heracle/core/storage/local_storage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _storage = LocalStorageService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTokenAndNavigate();
    });
  }

  Future<void> _checkTokenAndNavigate() async {
    try {
      final token = _storage.getAuthToken();

      if (token == null) {
        _goToAuth();
        return;
      }

      if (JwtDecoder.isExpired(token)) {
        await _storage.clearAuthToken();
        _goToAuth();
        return;
      }

      _goToHome();
    } catch (e) {
      debugPrint("Token check error: $e");
      _goToAuth();
    }
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  void _goToAuth() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/auth');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
