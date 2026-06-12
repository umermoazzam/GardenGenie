// contact_us_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // ✅ Required for calling and web functionality
import 'dart:convert';

// ✅ CONVERTED TO STATEFULWIDGET TO HANDLE LIVE REFRESH
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

  Map<String, String?> _memberImages = {};

  @override
  void initState() {
    super.initState();
    _loadAllMemberImages();
  }

  Future<void> _loadAllMemberImages() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _memberImages["umermoazzam2@gmail.com"] = prefs.getString('profile_image_path_umermoazzam2@gmail.com');
      _memberImages["m.haseebntu@gmail.com"] = prefs.getString('profile_image_path_m.haseebntu@gmail.com');
      _memberImages["beelalchaudhary@gmail.com"] = prefs.getString('profile_image_path_beelalchaudhary@gmail.com');
    });
  }

  // ✅ UPDATED: LAUNCHES OFFICIAL PLANTIO.PK INSTAGRAM PAGE
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
                        onTap: _launchInstagram, // ✅ Updated Clickable action
                        child: _buildSocialIcon("assets/icons/instagram.png"), // 👈 Used image asset path
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

  // ✅ UPDATED: Helper now accepts asset path String
  Widget _buildSocialIcon(String assetPath) {
    return Container(
      padding: const EdgeInsets.all(10), 
      decoration: BoxDecoration(
        shape: BoxShape.circle, 
        border: Border.all(color: Colors.grey.withOpacity(0.2))
      ), 
      child: Image.asset(assetPath, width: 22, height: 22), // Custom asset image
    );
  }

  Widget _buildContactCard(BuildContext context, String name, String email, String phone) {
    String? imgPath = _memberImages[email];
    bool hasImage = imgPath != null && File(imgPath).existsSync();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => TeamMemberProfileScreen(name: name, email: email, phone: phone))
        ).then((_) => _loadAllMemberImages()), 
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
                  image: hasImage ? DecorationImage(image: FileImage(File(imgPath!)), fit: BoxFit.cover) : null,
                ),
                child: !hasImage ? Icon(Icons.person, color: primaryGreen, size: 28) : null,
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

class TeamMemberProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phone;

  const TeamMemberProfileScreen({super.key, required this.name, required this.email, required this.phone});

  @override
  State<TeamMemberProfileScreen> createState() => _TeamMemberProfileScreenState();
}

class _TeamMemberProfileScreenState extends State<TeamMemberProfileScreen> {
  String? _profileImagePath;
  final ImagePicker _picker = ImagePicker();
  final Color primaryGreen = const Color(0xFF5B8E55);

  @override
  void initState() {
    super.initState();
    _loadMemberImage();
  }

  Future<void> _loadMemberImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImagePath = prefs.getString('profile_image_path_${widget.email}');
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch phone dialer")),
        );
      }
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
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mark_email_read_outlined, color: primaryGreen, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                'Inquiry Sent!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 12),
              Text(
                'The team member has been notified about your interest.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF666666), height: 1.4),
              ),
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

    // ✅ NEW: SHOW SENDING SNACKBAR
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Sending inquiry to ${widget.name}..."),
        backgroundColor: primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final response = await http.post(Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": widget.email, "name": widget.name, "customer_name": cName, "customer_email": cEmail}),
      );

      if (response.statusCode == 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide sending snackbar
          _showSuccessDialog(context);
        }
      } else {
        // ✅ NEW: SHOW ERROR SNACKBAR IF SERVER RETURNS ERROR
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 50);
      if (pickedFile != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_path_${widget.email}', pickedFile.path);
        setState(() { _profileImagePath = pickedFile.path; });
      }
    } catch (e) { debugPrint("Error: $e"); }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: Icon(Icons.photo_library, color: primaryGreen), title: const Text('Library'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
            ListTile(leading: Icon(Icons.camera_alt, color: primaryGreen), title: const Text('Camera'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasImage = _profileImagePath != null && File(_profileImagePath!).existsSync();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)), title: Text('Member Profile', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          const SizedBox(height: 30),
          GestureDetector(
            onTap: _showImagePickerOptions,
            child: Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFFF5F5F5),
                    backgroundImage: hasImage ? FileImage(File(_profileImagePath!)) : null,
                    child: !hasImage ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
                  ),
                  Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 18, backgroundColor: primaryGreen, child: const Icon(Icons.camera_alt, color: Colors.white, size: 18))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.name, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("Team Member", style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 40),
          
          _buildDetailTile(Icons.email_outlined, "Email Address", widget.email, onTap: () => _sendOfficialEmail(context)),
          _buildDetailTile(Icons.phone_outlined, "Phone Number", widget.phone, onTap: () => _makePhoneCall(widget.phone)),
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