import 'package:flutter/material.dart';
import 'package:heracle/src/auth/data/auth_repository.dart';
import '../../../route.dart'; // Added import for AppRoutes constants
import 'package:dio/dio.dart';
import 'package:heracle/core/storage/local_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'onboarding_page.dart';
import 'package:heracle/core/theme/app_colors.dart';
import 'terms_and_conditions_page.dart'; // Added // Added

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Ensure background is black
      body: Stack(
        children: [
          // Background Image (Top 75% of screen)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.75,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/login_image.jpg',
                  fit: BoxFit.cover,
                ),
                // Gradient Overlay at the bottom of the image for seamless transition
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.0),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This is Your Prime\nTime Wannabe.',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'it\'s zero subscription, 100% savage Download and dominate the fitness feed and dominate the feed forever.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Google Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await AuthRepository().signInWithGoogle();
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const OnboardingPage()),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Signin Failed: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Since we don't have a verified Google icon, we use a text label or icon placehoder
                         //Ideally this should be SvgPicture.asset('assets/icons/google.svg') but checking available icons showed none.
                         // Using a generic method or just text for now as per plan.
                        SvgPicture.asset(
                          'assets/icons/google.svg',
                          height: 24,
                          width: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Sign up with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Terms and Conditions
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TermsAndConditionsPage()),
                        );
                      },
                      child: Text.rich(
                        TextSpan(
                          text: 'By continuing, you agree to our ',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(
                              text: ' and ',
                            ),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(
                              text: '.',
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// End of file
