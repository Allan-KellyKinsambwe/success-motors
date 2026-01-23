// lib/screens/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:success_motors/constants/constants.dart';
import 'package:video_player/video_player.dart'; // ← NEW IMPORT
import 'onboarding_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset(
        'assets/videos/W1.mp4', // ← CHANGE TO YOUR VIDEO PATH
      );

      await _videoController.initialize();
      _videoController.setLooping(true);
      _videoController.setVolume(0.0); // mute by default (good for welcome)
      _videoController.play();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Video initialization error: $e');
      if (mounted) {
        setState(() {
          _hasVideoError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video background (plays if initialized, else fallback image)
          if (_isVideoInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            Image.asset(
              'assets/images/1.jpg', // fallback image
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),

          // Semi-transparent overlay (improves text readability on video)
          Container(
            color: Colors.black.withOpacity(0.45), // darker for video
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Welcome to Success Motors',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          blurRadius: 12,
                          color: Colors.black54,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your trusted partner for quality vehicles, rentals, financing & garage services in Uganda.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.95),
                      shadows: const [
                        Shadow(
                          blurRadius: 6,
                          color: Colors.black45,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: AppStyles.orangeButtonStyle.copyWith(
                        backgroundColor: WidgetStateProperty.all(
                          AppColors.orange,
                        ),
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 18),
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        elevation: WidgetStateProperty.all(8),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const OnboardingScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // Optional: small play/pause button (if you want user control)
          if (_isVideoInitialized)
            Positioned(
              bottom: 140,
              right: 24,
              child: FloatingActionButton.small(
                backgroundColor: Colors.black54,
                onPressed: () {
                  setState(() {
                    if (_videoController.value.isPlaying) {
                      _videoController.pause();
                    } else {
                      _videoController.play();
                    }
                  });
                },
                child: Icon(
                  _videoController.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
