import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';
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
      nextScreen = const RegisterScreen();
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
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1596547609652-9cf5d8d76921?q=80&w=1000',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (frame != null && !_imageLoaded) {
                  Future.microtask(() => setState(() => _imageLoaded = true));
                }
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 2500),
                  child: child,
                );
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFF2D3B2D).withOpacity(0.7),
            ),
          ),
          Center(
            child: AnimatedOpacity(
              opacity: _imageLoaded ? 1 : 0,
              duration: const Duration(milliseconds: 2500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: const Icon(Icons.eco_outlined, color: Colors.white, size: 45),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Plantio',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 47,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Gardening App',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 17,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.5,
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
