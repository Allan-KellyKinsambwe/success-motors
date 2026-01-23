// screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:success_motors/constants/constants.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(7, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
    });

    _animations = _controllers
        .map(
          (c) => Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)),
        )
        .toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: 300 + i * 150), () {
        if (mounted) _controllers[i].forward();
      });
    }

    Future.delayed(const Duration(milliseconds: 3800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (_, __, ___) => const WelcomeScreen(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle glow (orange tint)
            AnimatedBuilder(
              animation: _animations[6],
              builder: (_, child) => Opacity(
                opacity: _animations[6].value * 0.2,
                child: Container(
                  width: 260 * _animations[6].value,
                  height: 260 * _animations[6].value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.orange.withOpacity(0.3),
                  ),
                ),
              ),
            ),

            // Geometric "G" in orange
            SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(
                painter: GLogoPainter(
                  animations: _animations,
                  color: AppColors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GLogoPainter extends CustomPainter {
  final List<Animation<double>> animations;
  final Color color;

  GLogoPainter({required this.animations, this.color = Colors.orange});

  final Paint fillPaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    fillPaint.color = color;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.translate(center.dx, center.dy);

    final pieces = [
      [const Offset(-45, -60), const Offset(-20, -45), const Offset(-60, -20)],
      [const Offset(-20, -65), const Offset(10, -60), const Offset(-10, -40)],
      [const Offset(30, -50), const Offset(55, -30), const Offset(20, -30)],
      [const Offset(50, -10), const Offset(60, 20), const Offset(35, 10)],
      [const Offset(20, 40), const Offset(45, 55), const Offset(10, 55)],
      [const Offset(-30, 50), const Offset(-55, 30), const Offset(-40, 20)],
      [const Offset(-20, -10), const Offset(20, -15), const Offset(0, 15)],
    ];

    for (int i = 0; i < pieces.length; i++) {
      _drawPiece(canvas, pieces[i], animations[i].value);
    }
  }

  void _drawPiece(Canvas canvas, List<Offset> points, double progress) {
    if (progress == 0) return;
    final path = Path()
      ..moveTo(points[0].dx * progress, points[0].dy * progress);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx * progress, points[i].dy * progress);
    }
    path.close();

    canvas.save();
    canvas.rotate(progress * 0.3);
    canvas.scale(0.7 + progress * 0.3);
    canvas.drawPath(path, fillPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
