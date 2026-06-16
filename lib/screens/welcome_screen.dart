import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'register_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // 2. Dark Green Overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    const Color(0xFF2D3B2D).withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),
          
          // 3. Main Content (Shifted to Vertical Center)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // ✅ Pura content vertical center mein hai
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with Poppins Font
                  Text(
                    'Welcome\nTo Plantio',
                    style: GoogleFonts.poppins(
                      fontSize: 35,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Subtitle with Poppins Font
                  Text(
                    'Feel Fresh a with plant Worlds.\nit will enhance your living space!',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 60), // Space between text and buttons
                  
                  // Buttons Section
                  Column(
                    children: [
                      // REGISTER Button (Outlined)
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            // Isse border line thin ho jayegi
                            side: const BorderSide(color: Colors.white, width: 1.0),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero, // Sharp corners as requested
                            ),
                          ),
                          child: Text(
                            'REGISTER',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      
                      // LOGIN Button (Filled White)
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2D3B2D),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero, // Sharp corners as requested
                            ),
                          ),
                          child: Text(
                            'LOGIN',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
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