// lib/screens/profile/privacy_policy_screen.dart
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2E7D32)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Updated: December 08, 2025',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            _sectionTitle('1. Introduction'),
            const SizedBox(height: 10),
            const Text(
              'Welcome to FreshBasket. This Privacy Policy explains how we collect, use, and protect your information when you use our grocery delivery app.',
            ),
            const SizedBox(height: 20),
            _sectionTitle('2. Information We Collect'),
            const SizedBox(height: 10),
            const Text(
              '- Personal Info: Name, email, address, phone.\n- Order Data: Products ordered, payment details.\n- Device Info: IP, device type for security.',
            ),
            const SizedBox(height: 20),
            _sectionTitle('3. How We Use Your Information'),
            const SizedBox(height: 10),
            const Text(
              '- Process orders and deliveries.\n- Personalize recommendations.\n- Improve app features.',
            ),
            // Add more sections based on search results (adapted for grocery)
            const SizedBox(height: 20),
            _sectionTitle('4. Sharing Your Information'),
            const SizedBox(height: 10),
            const Text(
              'We share with delivery partners and payment processors only. No selling of data.',
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'I Accept',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2E7D32),
      ),
    );
  }
}
