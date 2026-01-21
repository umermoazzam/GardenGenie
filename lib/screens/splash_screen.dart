import 'package:flutter/material.dart';
import 'dart:async';
import 'register_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack)),
    );

    _animationController.forward();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RegisterScreen()),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const NetworkImage('https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=800'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(const Color(0xFF5A7562).withOpacity(0.6), BlendMode.multiply),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF6B8270).withOpacity(0.3),
                const Color(0xFF4A5F4E).withOpacity(0.5),
              ],
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Center(
                        child: CustomPaint(
                          size: const Size(40, 40),
                          painter: LeafIconPainter(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Plantio',
                      style: TextStyle(fontSize: 42, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Gardening App',
                      style: TextStyle(fontSize: 16, color: Colors.white, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LeafIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF4A9D6F)..style = PaintingStyle.fill;
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    path.moveTo(center.dx, center.dy - 15);
    path.quadraticBezierTo(center.dx - 12, center.dy, center.dx, center.dy + 15);
    path.quadraticBezierTo(center.dx + 12, center.dy, center.dx, center.dy - 15);
    canvas.drawPath(path, paint);
    canvas.drawLine(Offset(center.dx, center.dy - 15), Offset(center.dx, center.dy + 15), Paint()..color = const Color(0xFF4A9D6F)..strokeWidth = 2);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
