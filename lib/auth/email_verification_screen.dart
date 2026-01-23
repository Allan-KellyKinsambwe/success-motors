// screens/auth/email_verification_screen.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:success_motors/constants/constants.dart';
import 'package:success_motors/screens/home_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final User user;
  const EmailVerificationScreen({super.key, required this.user});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with TickerProviderStateMixin {
  late StreamSubscription<User?> _authSubscription;
  Timer? _countdownTimer;
  int _countdownSeconds = 120; // 2 minutes
  bool _canContinueManually = false;
  bool _isVerified = false;

  late AnimationController _successController;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    _startListeningToAuthChanges();
    _startCountdown();

    // Success checkmark animation
    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _successAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
  }

  void _startListeningToAuthChanges() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) async {
      if (user == null) return;

      await user.reload();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null &&
          currentUser.emailVerified &&
          mounted &&
          !_isVerified) {
        setState(() => _isVerified = true);
        _authSubscription.cancel();
        _countdownTimer?.cancel();

        // Play success animation
        _successController.forward().then((_) async {
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        });
      }
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds <= 1) {
        timer.cancel();
        if (mounted && !_isVerified) {
          setState(() => _canContinueManually = true);
        }
      } else {
        if (mounted && !_isVerified) {
          setState(() => _countdownSeconds--);
        }
      }
    });
  }

  String _formatCountdown() {
    int minutes = _countdownSeconds ~/ 60;
    int seconds = _countdownSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _manualContinue() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking verification status...')),
    );

    await widget.user.reload();
    final updatedUser = FirebaseAuth.instance.currentUser;

    if (updatedUser != null && updatedUser.emailVerified) {
      setState(() => _isVerified = true);
      _successController.forward().then((_) async {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not verified yet. Please check your inbox.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _resendEmail() async {
    try {
      await widget.user.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent again!')),
        );

        // Reset countdown
        setState(() {
          _countdownSeconds = 120;
          _canContinueManually = false;
        });
        _countdownTimer?.cancel();
        _startCountdown();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to resend email.')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated content switcher for icon → success checkmark
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: _isVerified
                  ? ScaleTransition(
                      scale: _successAnimation,
                      child: Icon(
                        Icons.check_circle,
                        size: 120,
                        color: Colors.green[600],
                      ),
                    )
                  : Icon(
                      Icons.mark_email_unread_outlined,
                      key: const ValueKey('email_icon'),
                      size: 100,
                      color: AppColors.orange,
                    ),
            ),

            const SizedBox(height: 32),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _isVerified
                  ? const Text(
                      'Email Verified!',
                      key: ValueKey('verified_title'),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    )
                  : const Text(
                      'Check Your Email',
                      key: ValueKey('check_email_title'),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),

            const SizedBox(height: 16),

            Text(
              _isVerified
                  ? 'Welcome to Success Motors!'
                  : 'We\'ve sent a verification link to\n${widget.user.email}',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            Text(
              _isVerified
                  ? 'Redirecting you to home...'
                  : 'Tap the link in the email to verify your account.\nYou\'ll be automatically signed in once verified.',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Countdown or Continue Button
            if (!_isVerified) ...[
              if (!_canContinueManually) ...[
                Text(
                  'Manual continue available in: ${_formatCountdown()}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: AppStyles.orangeButtonStyle.copyWith(
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    onPressed: _manualContinue,
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Resend Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _resendEmail,
                  child: const Text('Resend Verification Email'),
                ),
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: _signOut,
                child: const Text('Use Different Email'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _countdownTimer?.cancel();
    _successController.dispose();
    super.dispose();
  }
}
