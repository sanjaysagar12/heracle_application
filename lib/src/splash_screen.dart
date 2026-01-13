import 'package:flutter/material.dart';
import 'package:heracle/core/theme/app_colors.dart';
import 'package:heracle/route.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:heracle/core/storage/local_storage.dart';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:heracle/core/network/dio_client.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _storage = LocalStorageService();
  final _dio = DioClient().dio;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
    });
  }

  Future<void> _initApp() async {
    final shouldProceed = await _checkAppVersion();
    if (!shouldProceed) return;
    final isFirstLaunch = _storage.isFirstLaunch();
    if (isFirstLaunch) {
      _goToOnboarding();
      return;
    }

    _checkTokenAndNavigate();
  }

  void _goToOnboarding() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
  }

  Future<bool> _checkAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final platform = Platform.isAndroid ? 'android' : 'ios';
      final currentVersion = packageInfo.version;

      final res = await _dio.get(
        '/api/version',
        queryParameters: {'version': currentVersion, 'platform': platform},
      );

      if (res.statusCode == 200) {
        final data = res.data;
        final bool updateRequired = data['updateRequired'] ?? false;
        final bool updateAvailable = data['updateAvailable'] ?? false;

        // Only show dialog if update is available or required
        if (updateAvailable || updateRequired) {
          if (!mounted) return false;
          return await _showUpdateDialog(updateRequired, data['latestVersion']);
        }
      }
      return true;
    } catch (e) {
      debugPrint("Version check failed: $e");
      // On error, we proceed (fail open) unless deemed critical
      return true;
    }
  }

  Future<bool> _showUpdateDialog(bool isRequired, String? latestVersion) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: !isRequired,
          builder: (context) {
            return AlertDialog(
              title: const Text('Update Available'),
              content: Text(
                isRequired
                    ? 'A critical update ($latestVersion) is required to continue. Please update the app.'
                    : 'A new version ($latestVersion) is available. Would you like to update?',
              ),
              actions: [
                if (!isRequired)
                  TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(true), // Continue without update
                    child: const Text('Later'),
                  ),
                TextButton(
                  onPressed: () {
                    // Here we would open the store url.
                    // For now, if required, we don't dismiss or we exit.
                    // Since we don't have url_launcher setup in this task, we just log it.
                    debugPrint("User clicked Update");
                    // typically launchUrl(Uri.parse(storeUrl));
                  },
                  child: const Text('Update Now'),
                ),
              ],
            );
          },
        ) ??
        !isRequired; // If dialog dismissed (and allowed), return true (proceed)
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
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/login_image.jpg', fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.9),
                ],
              ),
            ),
          ),
          const Center(
            child: Text(
              'HERACLE',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}