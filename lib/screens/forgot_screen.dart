import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showValidationDialog(String message) {
    String iconPath = message.toLowerCase().contains('not registered') 
        ? 'assets/images/not_registered.png' 
        : 'assets/images/registered_email.png';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                iconPath,
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.info_outline,
                  size: 40,
                  color: Color(0xFF5B8E55),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold, // BOLD
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF5B8E55),
                      fontWeight: FontWeight.bold, // BOLD
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSendResetLink() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      _showValidationDialog('Please enter your registered email!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.forgotPassword(email: email);

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      _showSuccessDialog(context);
    } else {
      _showValidationDialog(result['message'] ?? 'Error occurred');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF5B8E55);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    child: const Icon(Icons.eco, color: primaryGreen, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Plantio', 
                    style: GoogleFonts.inter(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold // BOLD
                    )
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                'Forgot Password?',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold, // BOLD
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Don\'t worry! It happens. Please enter the email address associated with your account.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF666666),
                  height: 1.5,
                  fontWeight: FontWeight.bold // BOLD
                ),
              ),
              const SizedBox(height: 40),
              _buildInputField(
                Icons.email_outlined,
                'Email Address',
                _emailController,
                primaryGreen: primaryGreen,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendResetLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'SEND RESET LINK',
                          style: GoogleFonts.inter(
                            fontSize: 16, 
                            color: Colors.white, 
                            fontWeight: FontWeight.bold // BOLD
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Remember password? ', 
                    style: GoogleFonts.inter(
                      fontSize: 14, 
                      color: const Color(0xFF666666),
                      fontWeight: FontWeight.bold // BOLD
                    )
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: Text(
                      'Login',
                      style: GoogleFonts.inter(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold, // BOLD
                        fontSize: 14,
                      ),
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

  Widget _buildInputField(
    IconData icon,
    String hint,
    TextEditingController controller, {
    bool obscureText = false,
    TextInputType? keyboardType,
    Color primaryGreen = Colors.green,
  }) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFFAFAFA)), // Match Login
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        // ✅ Typed text is Normal (Simple)
        style: GoogleFonts.inter(
          fontWeight: FontWeight.normal,
          color: const Color(0xFF1A1A1A),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hint,
          // ✅ Placeholder (Hint) text is BOLD
          hintStyle: GoogleFonts.inter(
            color: Colors.grey[400],
            fontWeight: FontWeight.bold,
          ),
          prefixIcon: Icon(icon, color: primaryGreen, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/sent_mail.png', // Corrected path to match typical structure
                width: 50,
                height: 50,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.mark_email_read_outlined,
                  size: 50,
                  color: Color(0xFF5B8E55),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Check your Email!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold, // BOLD
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Password recovery link sent to your email.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF666666),
                  height: 1.4,
                  fontWeight: FontWeight.bold // BOLD
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF5B8E55),
                      fontWeight: FontWeight.bold, // BOLD
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}