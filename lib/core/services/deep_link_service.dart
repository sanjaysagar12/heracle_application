import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../../route.dart';
import '../../src/home/presentation/workout_details_page.dart';
import '../../src/home/presentation/nutrition_details_page.dart';
import '../../app.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  GlobalKey<NavigatorState>? _navigatorKey;
  Uri? _pendingInitialUri;

  void init(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Handle initial link (when app is opened from closed state)
    try {
      _pendingInitialUri = await _appLinks.getInitialLink();
      if (_pendingInitialUri != null) {
        debugPrint('🔗 DeepLinkService: Pending initial link found: $_pendingInitialUri');
        _handleUri(_pendingInitialUri!);
      }
    } catch (e) {
      debugPrint('Error getting initial deep link: $e');
    }

    // Subscribe to links (when app is already running)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (err) => debugPrint('Deep link error: $err'),
    );
  }

  void _handleUri(Uri uri) {
    debugPrint('🔗 DeepLinkService: Handling deep link: $uri');
    
    String? type;
    String? id;

    if (uri.scheme == 'heracle') {
      type = uri.host;
      if (uri.pathSegments.isNotEmpty) {
        id = uri.pathSegments[0];
      }
    } else {
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2) {
        type = pathSegments[0];
        id = pathSegments[1];
      }
    }

    if (type == null || id == null) return;

    Widget? page;
    switch (type) {
      case 'workout':
        page = WorkoutDetailsPage(postId: id);
        break;
      case 'nutrition':
        page = NutritionDetailsPage(postId: id);
        break;
    }

    if (page != null) {
      _navigateTo(page);
    }
  }

  void _navigateTo(Widget page) {
    // Wait for the app to finish its initial splash navigation
    // We wait 2 seconds to ensure authentication check and splash navigation are done
    Future.delayed(const Duration(milliseconds: 2000), () {
      final navigatorState = _navigatorKey?.currentState;
      if (navigatorState == null) return;

      // Check if we are still on Splash or have a clean stack
      // If we can't pop, we should ensure the Home page is the base
      if (!navigatorState.canPop()) {
        navigatorState.pushNamedAndRemoveUntil(
          AppRoutes.home,
          (route) => false,
        );
      }

      // Push the detail page on top
      navigatorState.push(
        MaterialPageRoute(builder: (_) => page),
      );
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
