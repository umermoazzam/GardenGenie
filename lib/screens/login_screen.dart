// login_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'forgot_screen.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🔹 Firebase Google Auth
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 🔹 Google Auth Service
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================= EMAIL / PASSWORD LOGIN (UNCHANGED) =================
  void _loginUser() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', result['user']['name']);
      await prefs.setString('userEmail', result['user']['email']);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Login failed')),
      );
    }
  }

  // ================= GOOGLE LOGIN (FROM FRIEND CODE) =================
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authService.signInWithGoogle();

      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF5B8E55);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
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

              _buildInputField(Icons.email_outlined, 'Email', _emailController,
                  primaryGreen: primaryGreen, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
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
                      Text('Remember Me',
                          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF666666))),
                    ],
                  ),
                  GestureDetector(
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
                ],
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _loginUser,
                  style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text('LOGIN', style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
                ),
              ),

              const SizedBox(height: 20),

              // ================= GOOGLE BUTTON =================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _loginWithGoogle,
                  icon: Image.asset(
                    'assets/google_logo.png',
                    height: 22,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.g_mobiledata, size: 26),
                  ),
                  label: Text(
                    'Continue with Google',
                    style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Don\'t have an account? ',
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF666666))),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: Text('Sign up',
                        style: GoogleFonts.inter(
                            color: primaryGreen, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5)),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: primaryGreen),
          suffixIcon: isPasswordField
              ? IconButton(
                  icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
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
