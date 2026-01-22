// login_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'forgot_screen.dart'; // <- added import for ForgotPasswordScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  bool _obscurePassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loginUser() {
    if (_emailController.text == registeredUser['email'] &&
        _passwordController.text == registeredUser['password']) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect email or password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF5B8E55); // Updated color (#5B8E55)

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo + Header
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryGreen, width: 2),
                    ),
                    child: Icon(Icons.eco, color: primaryGreen, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Plantio',
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                  children: [
                    const TextSpan(text: 'Login on '),
                    TextSpan(text: 'Plantio', style: TextStyle(color: primaryGreen)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Login to your account to continue.',
                style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF666666)),
              ),
              const SizedBox(height: 40),

              // Email field
              _buildInputField(Icons.email_outlined, 'Email', _emailController, primaryGreen: primaryGreen,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),

              // Password field with eye icon
              _buildInputField(Icons.lock_outline, 'Password', _passwordController,
                  obscureText: _obscurePassword,
                  isPasswordField: true,
                  toggleObscure: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  primaryGreen: primaryGreen),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) => setState(() => _rememberMe = value ?? false),
                        activeColor: primaryGreen,
                      ),
                      Text('Remember Me', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF666666))),
                    ],
                  ),
                  // Forgot Password? with pointer cursor and navigation
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                        );
                      },
                      child: Text('Forgot Password?',
                          style: GoogleFonts.inter(
                              fontSize: 14, color: primaryGreen, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // LOGIN Button (square)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: const RoundedRectangleBorder(), // square button
                  ),
                  child: Text('LOGIN', style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),

              // Sign up link with pointer cursor
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Don\'t have an account? ', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF666666))),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: Text('Sign up',
                          style: GoogleFonts.inter(color: primaryGreen, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable input field
  Widget _buildInputField(
    IconData icon,
    String hint,
    TextEditingController controller, {
    bool obscureText = false,
    bool isPasswordField = false,
    VoidCallback? toggleObscure,
    TextInputType? keyboardType,
    Color primaryGreen = Colors.green,
  }) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5)), // square field
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: primaryGreen),
          suffixIcon: isPasswordField
              ? IconButton(
                  icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: primaryGreen),
                  onPressed: toggleObscure,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
