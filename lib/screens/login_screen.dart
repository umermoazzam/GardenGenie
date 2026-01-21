import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'home_screen.dart';

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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2D5F3F), width: 2.5),
                    ),
                    child: const Icon(Icons.eco, color: Color(0xFF2D5F3F), size: 24),
                  ),
                  const SizedBox(width: 10),
                  const Text('Plantio', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                ],
              ),
              const SizedBox(height: 50),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A), height: 1.2),
                  children: [
                    TextSpan(text: 'Login on '),
                    TextSpan(text: 'Plantio', style: TextStyle(color: Color(0xFF4A9D6F))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Create an Aepod account, We can\'t wait to have you.', style: TextStyle(fontSize: 15, color: Color(0xFF666666), height: 1.5)),
              const SizedBox(height: 40),

              _buildFieldContainer(
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Email', Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              _buildFieldContainer(
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration('Password', Icons.lock_outline).copyWith(
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0, top: 15),
                        child: Text(_obscurePassword ? 'show' : 'hide', style: const TextStyle(color: Color(0xFF4A9D6F), fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) => setState(() => _rememberMe = value ?? false),
                        activeColor: const Color(0xFF4A9D6F),
                      ),
                      const Text('Remember Me', style: TextStyle(color: Color(0xFF666666))),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF4A9D6F), fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A9D6F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('LOGIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Don\'t have an account? ', style: TextStyle(color: Color(0xFF666666))),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                    },
                    child: const Text('Sign up', style: TextStyle(color: Color(0xFF4A9D6F), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldContainer(Widget child) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF4A9D6F), size: 22),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }
}
