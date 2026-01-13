import 'package:flutter/material.dart';
import 'package:heracle/core/storage/local_storage.dart';
import 'package:heracle/route.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      image: 'assets/images/splash_page/splash1.png',
      title: 'Snap. Scan. Track.\nShare. Inspire.',
      description:
          "Snap any meal photo and Heracle's AI instantly detects calories, protein, carbs, and fat in under 2 seconds.",
    ),
    OnboardingData(
      image: 'assets/images/splash_page/splash2.png',
      title: 'Log. Lift. Post.\nMotivate. Repeat.',
      description:
          "Complete workouts and instantly post summaries or videos to stories. Share your grind with friends.",
    ),
    OnboardingData(
      image: 'assets/images/splash_page/splash3.png',
      title: 'Follow. Copy.\nTransform. Excel.',
      description:
          'One-tap copy any workout plan, meal macro, or exercise session. Adapt proven routines to your level.',
    ),
  ];

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    LocalStorageService().setOnboardingSeen();
    Navigator.pushReplacementNamed(context, AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    // Fixed height for bottom black section - consistent across all pages
    const double bottomBarHeight = 320;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Image section - fills remaining space above bottom bar
          Expanded(
            child: Stack(
              children: [
                // PageView with images
                PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Image.asset(
                      _pages[index].image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      alignment: Alignment.topCenter,
                    );
                  },
                ),
                // Gradient overlay at bottom of image
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 80,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom content section - solid black, fixed height
          SafeArea(
            top: false,
            child: Container(
              height: bottomBarHeight,
              color: Colors.black,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page indicators
                  _buildPageIndicators(),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    _pages[_currentPage].title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Description
                  Expanded(
                    child: Text(
                      _pages[_currentPage].description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5A5F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Continue',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      children: List.generate(_pages.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 8),
          height: 8,
          width: isActive ? 24 : 8,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFFF5A5F)
                : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class OnboardingData {
  final String image;
  final String title;
  final String description;

  OnboardingData({
    required this.image,
    required this.title,
    required this.description,
  });
}
