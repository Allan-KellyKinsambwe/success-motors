// lib/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:success_motors/auth/login_screen.dart';
import 'package:success_motors/constants/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Discover Premium Vehicles",
      "subtitle":
          "Browse our wide selection of quality new and used cars, imported with care for Ugandan roads.",
      "image": "assets/products/o1.jpg",
    },
    {
      "title": "Trusted Dealership",
      "subtitle":
          "Transparent deals, expert advice, and thousands of happy customers in Kampala and across Uganda.",
      "image": "assets/products/o2.jpg",
    },
    {
      "title": "Drive Your Dream Car",
      "subtitle":
          "Flexible financing options and full ownership support. Your perfect vehicle is just a step away.",
      "image": "assets/products/o3.jpg",
    },
    {
      "title": "Flexible Car Rentals",
      "subtitle":
          "Short or long-term rentals with well-maintained vehicles. Self-drive or chauffeured — explore Uganda freely!",
      "image": "assets/products/102.jpg",
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // PageView with your original images
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return OnboardingPage(data: _onboardingData[index]);
            },
          ),

          // Skip Button (white text so visible on dark overlay)
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 24,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text(
                "Skip",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Bottom Section: Indicator + Button
          Positioned(
            bottom: 60,
            left: 32,
            right: 32,
            child: Column(
              children: [
                // Page indicator (white dots for visibility)
                SmoothPageIndicator(
                  controller: _pageController,
                  count: _onboardingData.length,
                  effect: ExpandingDotsEffect(
                    activeDotColor: AppColors.orange,
                    dotColor: Colors.white.withOpacity(0.5),
                    dotHeight: 10,
                    dotWidth: 10,
                    expansionFactor: 4,
                    spacing: 8,
                  ),
                ),
                const SizedBox(height: 40),

                // Next / Get Started Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: AppStyles.orangeButtonStyle,
                    onPressed: () {
                      if (_currentPage == _onboardingData.length - 1) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                      _currentPage == _onboardingData.length - 1
                          ? "Get Started"
                          : "Next",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final Map<String, String> data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Your original image — unchanged
        Image.asset(
          data["image"]!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),

        // Black overlay you liked (exactly the same as Welcome screen)
        Container(color: Colors.black.withOpacity(0.45)),

        // Content — white text + shadows for readability
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                data["title"]!,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 12,
                      color: Colors.black54,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                data["subtitle"]!,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  height: 1.5,
                  shadows: [
                    Shadow(
                      blurRadius: 6,
                      color: Colors.black45,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 120), // space for bottom button
            ],
          ),
        ),
      ],
    );
  }
}
