import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_screen.dart'; // ✅ Imported WelcomeScreen
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkNavigation();
  }

  void _checkNavigation() async {
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;

    Widget nextScreen;
    if (user != null) {
      nextScreen = const HomeScreen();
    } else {
      nextScreen = const WelcomeScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => nextScreen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_screen.jpg', 
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (frame != null && !_imageLoaded) {
                  Future.microtask(() => setState(() => _imageLoaded = true));
                }
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 3000),
                  child: child,
                );
              },
            ),
          ),
          // Dark Overlay
          Positioned.fill(
            child: Container(
              color: const Color(0xFF2D3B2D).withOpacity(0.7),
            ),
          ),
          // Main Centered Content
          Center(
            child: AnimatedOpacity(
              opacity: _imageLoaded ? 1 : 0,
              duration: const Duration(milliseconds: 3500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row for Icon and Title
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.eco_outlined, color: Colors.white, size: 12),
                      ),
                      const SizedBox(width: 10), // Icon aur Text ke beech ka fasla
                      Text(
                        'Plantio',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 30,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5), // Title aur Tagline ke beech ka fasla
                  Text(
                    'Gardening App',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.8,
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
}