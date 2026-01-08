import 'package:flutter/material.dart';
import '/src/workout/presentation/workout_page.dart';
import 'src/camera/presentation/camera_page.dart';
import 'src/feed/presentation/feed_page.dart';
import 'src/home/presentation/home_page.dart';
import 'src/profile/presentation/profile_page.dart';
import 'widgets/nav_bar.dart';

class AppPage extends StatefulWidget {
  final int initialIndex;
  const AppPage({super.key, this.initialIndex = 0});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> with TickerProviderStateMixin {
  int _index = 0;
  bool _isNavBarVisible = true;
  late AnimationController _navBarAnimationController;
  late Animation<Offset> _navBarSlideAnimation;
  final List<ScrollController> _scrollControllers = [];

  final GlobalKey<WorkoutPageState> _workoutKey = GlobalKey(); // Key to control WorkoutPage
  late final List<Widget> pages; // Late init

  // Method to change tab programmatically
  void _changeTab(int index) {
    setState(() {
      _index = index;
    });
    if (index == 3) {
      _workoutKey.currentState?.refresh();
    }
  }

  Widget _buildPage(int index) {
    if (index == 2) {
      // Feed page with callback to navigate to camera
      return FeedPage(
        onNavigateToCamera: _openCamera,
      );
    }
    return pages[index];
  }

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    
    // Initialize pages here to use _workoutKey
    pages = [
      const HomePage(),
      Container(),
      const FeedPage(),
      WorkoutPage(key: _workoutKey),
    ];
    
    // Initialize animation controller for navbar
    _navBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _navBarSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1),
    ).animate(CurvedAnimation(
      parent: _navBarAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Create scroll controllers for each page
    for (int i = 0; i < pages.length; i++) {
      _scrollControllers.add(ScrollController());
    }
    
    // Add scroll listeners
    _addScrollListeners();
  }
  
  @override
  void dispose() {
    _navBarAnimationController.dispose();
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  void _addScrollListeners() {
    for (int i = 0; i < _scrollControllers.length; i++) {
      _scrollControllers[i].addListener(() => _handleScroll(i));
    }
  }
  
  double _lastScrollPosition = 0;
  void _handleScroll(int pageIndex) {
    if (pageIndex != _index) return; // Only handle scroll for current page
    
    final currentScrollPosition = _scrollControllers[pageIndex].position.pixels;
    final scrollDelta = currentScrollPosition - _lastScrollPosition;
    
    // Only trigger on significant scroll changes
    if (scrollDelta.abs() < 10) return;
    
    if (scrollDelta > 0 && _isNavBarVisible) {
      // Scrolling down - hide navbar
      setState(() {
        _isNavBarVisible = false;
      });
      _navBarAnimationController.forward();
    } else if (scrollDelta < 0 && !_isNavBarVisible) {
      // Scrolling up - show navbar
      setState(() {
        _isNavBarVisible = true;
      });
      _navBarAnimationController.reverse();
    }
    
    _lastScrollPosition = currentScrollPosition;
  }

  void _openCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraPage()),
    ).then((result) {
      if (mounted) {
        setState(() => _isNavBarVisible = true);
        _navBarAnimationController.reverse();
        
        if (result is int) {
          setState(() => _index = result);
          if (_index == 3) _workoutKey.currentState?.refresh(); // Refresh if navigated to Workout
        }
      }
    });

    if (mounted) {
      setState(() => _isNavBarVisible = false);
      _navBarAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: pages.asMap().entries.map((entry) {
          int pageIndex = entry.key;
          Widget page = pageIndex == 2 ? _buildPage(pageIndex) : entry.value;
          
          // Wrap scrollable pages with ScrollController
          if (pageIndex == 0 || pageIndex == 3) { // HomePage and WorkoutPage
            return _wrapWithScrollController(page, pageIndex);
          }
          return page;
        }).toList(),
      ),
      bottomNavigationBar: SlideTransition(
        position: _navBarSlideAnimation,
        child: FloatingNavBar(
          currentIndex: _index,
          onTap: (i) {
            if (i == 1) {
              _openCamera();
              return;
            }
            setState(() => _index = i);
            if (i == 3) {
              _workoutKey.currentState?.refresh(); // Refresh Workout Page
            }
            _lastScrollPosition = 0;
          },
        ),
      ),
    );
  }

  Widget _wrapWithScrollController(Widget page, int pageIndex) {
    // For pages that need scroll detection, we need to provide the ScrollController
    // This requires modifying the pages to accept a ScrollController parameter
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollUpdateNotification && pageIndex == _index) {
          final scrollDelta = notification.scrollDelta ?? 0;
          
          if (scrollDelta > 5 && _isNavBarVisible) {
            // Scrolling down - hide navbar
            setState(() {
              _isNavBarVisible = false;
            });
            _navBarAnimationController.forward();
          } else if (scrollDelta < -5 && !_isNavBarVisible) {
            // Scrolling up - show navbar
            setState(() {
              _isNavBarVisible = true;
            });
            _navBarAnimationController.reverse();
          }
        }
        return false;
      },
      child: page,
    );
  }
}
