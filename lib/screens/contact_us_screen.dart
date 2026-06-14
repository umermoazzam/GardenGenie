// contact_us_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; 
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final Color primaryGreen = const Color(0xFF5B8E55);
  final Color textBlack = const Color(0xFF1A1A1A);
  final Color textGrey = const Color(0xFF666666);
  final Color cardBg = const Color(0xFFF9F9F9);

  // Fixed Asset Mapping for Team Members
  final Map<String, String> _memberAssets = {
    "umermoazzam2@gmail.com": "assets/images/umer.jpeg",
    "m.haseebntu@gmail.com": "assets/images/haseeb.jpeg",
    "beelalchaudhary@gmail.com": "assets/images/beelal.png",
  };

  Future<void> _launchInstagram() async {
    const String instagramUrl = "https://www.instagram.com/plantio.pk/"; 
    final Uri url = Uri.parse(instagramUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch Instagram")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Contact Us",
          style: GoogleFonts.inter(color: textBlack, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Get in Touch", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: textBlack)),
            const SizedBox(height: 8),
            Text("Our team is here to help you with any questions or concerns about your plants.", style: GoogleFonts.inter(fontSize: 14, color: textGrey, height: 1.5)),
            const SizedBox(height: 30),
            _buildSupportSection(Icons.headset_mic_outlined, "Customer Support", "support@plantio.com"),
            const SizedBox(height: 30),
            Text("Our Team", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textBlack)),
            const SizedBox(height: 16),
            _buildContactCard(context, "Umer Moazzam", "umermoazzam2@gmail.com", "+923326582650"),
            _buildContactCard(context, "Muhammad Haseeb Shahid", "m.haseebntu@gmail.com", "+923166415699"),
            _buildContactCard(context, "Muhammad Bilal Afzal", "beelalchaudhary@gmail.com", "+923424882223"),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withOpacity(0.1))),
              child: Row(children: [Icon(Icons.access_time, color: primaryGreen, size: 20), const SizedBox(width: 12), Text("Mon - Fri: 9:00 AM to 6:00 PM", style: GoogleFonts.inter(fontSize: 14, color: textGrey))]),
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Text("Follow our journey", style: GoogleFonts.inter(fontSize: 13, color: textGrey)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _launchInstagram,
                        child: _buildSocialIcon("assets/icons/instagram.png"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportSection(IconData icon, String title, String subtitle) {
    return Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: primaryGreen, size: 24)), const SizedBox(width: 16), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)), Text(subtitle, style: GoogleFonts.inter(fontSize: 14, color: textGrey))])]);
  }

  Widget _buildSocialIcon(String assetPath) {
    return Container(
      padding: const EdgeInsets.all(10), 
      decoration: BoxDecoration(
        shape: BoxShape.circle, 
        border: Border.all(color: Colors.grey.withOpacity(0.2))
      ), 
      child: Image.asset(assetPath, width: 22, height: 22),
    );
  }

  Widget _buildContactCard(BuildContext context, String name, String email, String phone) {
    String? assetPath = _memberAssets[email];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => TeamMemberProfileScreen(name: name, email: email, phone: phone, assetPath: assetPath))
        ), 
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: Colors.white, 
                  shape: BoxShape.circle, 
                  border: Border.all(color: primaryGreen.withOpacity(0.2)),
                ),
                child: ClipOval(
                  child: Image.asset(
                    assetPath ?? "",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: primaryGreen, size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: textBlack)), const SizedBox(height: 4), Text(email, style: GoogleFonts.inter(fontSize: 12, color: textGrey))])),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class TeamMemberProfileScreen extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final String? assetPath;

  const TeamMemberProfileScreen({
    super.key, 
    required this.name, 
    required this.email, 
    required this.phone,
    this.assetPath,
  });

  final Color primaryGreen = const Color(0xFF5B8E55);

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.mark_email_read_outlined, color: primaryGreen, size: 40),
              ),
              const SizedBox(height: 20),
              Text('Inquiry Sent!', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 12),
              Text('The team member has been notified about your interest.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF666666), height: 1.4)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK', style: GoogleFonts.inter(color: primaryGreen, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendOfficialEmail(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final String cName = prefs.getString('userName') ?? prefs.getString('name') ?? "A Plantio User";
    final String cEmail = prefs.getString('userEmail') ?? prefs.getString('email') ?? "No Email Available";
    const String apiUrl = "https://umermoazzam-plantio-backend.hf.space/api/contact-inquiry";

    try {
      final response = await http.post(Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "name": name, "customer_name": cName, "customer_email": cEmail}),
      );

      if (response.statusCode == 200) {
        if (context.mounted) {
          _showSuccessDialog(context);
        }
      } else {
        final errorData = jsonDecode(response.body);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${errorData['message']}"), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connection error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0, 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black), 
          onPressed: () => Navigator.pop(context)
        ), 
        title: Text('Member Profile', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold))
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFFF5F5F5),
              child: ClipOval(
                child: Image.asset(
                  assetPath ?? "",
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 60, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(name, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("Team Member", style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 40),
          _buildDetailTile(Icons.email_outlined, "Email Address", email, onTap: () => _sendOfficialEmail(context)),
          _buildDetailTile(Icons.phone_outlined, "Phone Number", phone, onTap: () => _makePhoneCall(phone)),
          _buildDetailTile(Icons.work_outline, "Department", "Plant Care Specialist"),
        ],
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(icon, color: primaryGreen, size: 24),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)), const SizedBox(height: 2), Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500))])),
              if (onTap != null) Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}