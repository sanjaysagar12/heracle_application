import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../../src/home/presentation/workout_details_page.dart';
import '../../src/home/presentation/nutrition_details_page.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  GlobalKey<NavigatorState>? _navigatorKey;

  void init(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Handle initial link (when app is opened from closed state)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
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
      // Format: heracle://workout/id
      type = uri.host;
      if (uri.pathSegments.isNotEmpty) {
        id = uri.pathSegments[0];
      }
    } else {
      // Format: https://heracle.fit/workout/id
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2) {
        type = pathSegments[0];
        id = pathSegments[1];
      }
    }

    debugPrint('🔗 DeepLinkService: Parsed Type: $type, ID: $id');

    if (type == null || id == null) {
      debugPrint('🔗 DeepLinkService: Invalid deep link format');
      return;
    }

    switch (type) {
      case 'workout':
        debugPrint('🔗 DeepLinkService: Navigating to Workout: $id');
        _navigateTo(WorkoutDetailsPage(postId: id));
        break;
      case 'nutrition':
        debugPrint('🔗 DeepLinkService: Navigating to Nutrition: $id');
        _navigateTo(NutritionDetailsPage(postId: id));
        break;
      default:
        debugPrint('🔗 DeepLinkService: Unknown type: $type');
    }
  }

  void _navigateTo(Widget page) {
    // Wait a bit for the app to be ready if it just launched
    Future.delayed(const Duration(milliseconds: 500), () {
      _navigatorKey?.currentState?.push(
        MaterialPageRoute(builder: (_) => page),
      );
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
