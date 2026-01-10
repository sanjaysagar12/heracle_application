import 'package:flutter/material.dart';
import 'package:heracle/core/theme/app_colors.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Terms & Privacy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('1. Introduction'),
            _buildParagraph(
                'Welcome to Heracle ("we," "our," or "us"). By accessing or using our mobile application, you agree to be bound by these Terms of Service and our Privacy Policy.'),
            const SizedBox(height: 16),
            _buildSectionTitle('2. Health Disclaimer'),
            _buildParagraph(
                'Heracle provides fitness and nutrition tracking features. We are not a medical organization, and our app should not be used for medical advice or diagnosis. Always consult with a physician before starting any diet or exercise program.'),
            const SizedBox(height: 16),
            _buildSectionTitle('3. User Accounts'),
            _buildParagraph(
                'You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorized use of your account. We reserve the right to terminate accounts that violate our community guidelines.'),
            const SizedBox(height: 16),
            _buildSectionTitle('4. AI Features'),
            _buildParagraph(
                'Our "Cal AI" feature uses artificial intelligence to estimate nutritional information from images. These estimates may not be 100% accurate. You should verify important nutritional data independently.'),
            const SizedBox(height: 16),
            _buildSectionTitle('5. User Content'),
            _buildParagraph(
                'By posting content (photos, videos, comments) to Heracle, you grant us a non-exclusive license to use, display, and distribute your content on the platform. You retain ownership of your content.'),
            const SizedBox(height: 16),
            _buildSectionTitle('6. Privacy Policy'),
            _buildParagraph(
                'We collect information you provide directly (e.g., profile data, workout logs) and usage data to improve the app. We do not sell your personal data to third parties. We may use your data to train our AI models to improve feature accuracy.'),
            const SizedBox(height: 16),
            _buildSectionTitle('7. Changes to Terms'),
            _buildParagraph(
                'We may modify these terms at any time. Continued use of the app constitutes acceptance of the new terms.'),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        height: 1.5,
      ),
    );
  }
}
