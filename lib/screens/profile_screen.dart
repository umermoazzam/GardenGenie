import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

// ✅ MAINTAINED IMPORTS
import 'contact_us_screen.dart';
import 'admin_screen.dart'; 
import 'history_screen.dart'; 
import 'shipping_address.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "Loading...";
  String _userEmail = "Loading...";
  String? _profileImagePath;

  final Color primaryGreen = const Color(0xFF5B8E55);
  final Color textBlack = const Color(0xFF1A1A1A);
  final Color textGrey = const Color(0xFF666666);
  final Color bgGrey = const Color(0xFFF5F5F5);

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final User? user = FirebaseAuth.instance.currentUser;
    
    setState(() {
      _userName = prefs.getString('userName') ?? user?.displayName ?? "User";
      _userEmail = prefs.getString('userEmail') ?? user?.email ?? "";
      _profileImagePath = prefs.getString('profile_image_path');

      if (_profileImagePath != null && !File(_profileImagePath!).existsSync()) {
        _profileImagePath = null;
      }
    });
  }

  Future<void> _logout() async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            content: Text(
              'Are you sure you want to logout?',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500), // Updated to Poppins
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500)), // Updated to Poppins
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500)), // Updated to Poppins
              ),
            ],
          ),
        ) ?? false;

    if (confirm) {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 50);
      if (pickedFile != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_path', pickedFile.path);
        setState(() => _profileImagePath = pickedFile.path);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<void> _removeImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_image_path');
    setState(() => _profileImagePath = null);
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF5B8E55)),
                title: Text('Choose from library', style: GoogleFonts.poppins()), // Updated to Poppins
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF5B8E55)),
                title: Text('Take photo', style: GoogleFonts.poppins()), // Updated to Poppins
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              ),
              if (_profileImagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text('Remove current picture', style: GoogleFonts.poppins(color: Colors.red)), // Updated to Poppins
                  onTap: () { Navigator.pop(context); _removeImage(); },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String emailFromPrefs = _userEmail.toLowerCase().trim();
    final String emailFromFirebase = (FirebaseAuth.instance.currentUser?.email ?? "").toLowerCase().trim();
    final String authorizedEmail = emailFromPrefs.isNotEmpty ? emailFromPrefs : emailFromFirebase;
    
    bool isAdmin = authorizedEmail == "click.umer50@gmail.com" || 
                   authorizedEmail == "beelalchaudhary@gmail.com" ||
                   authorizedEmail == "rmubeensaeed2222@gmail.com";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white, 
        elevation: 0,
        scrolledUnderElevation: 0, 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Profile', style: GoogleFonts.poppins(color: textBlack, fontSize: 18, fontWeight: FontWeight.w700)), // Updated to Poppins
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showImagePickerOptions,
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: (_profileImagePath != null && File(_profileImagePath!).existsSync())
                            ? FileImage(File(_profileImagePath!)) as ImageProvider
                            : const AssetImage('assets/icons/user.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryGreen, 
                        shape: BoxShape.circle, 
                        border: Border.all(color: Colors.white, width: 2)
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(_userName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: textBlack)), // Updated to Poppins
            const SizedBox(height: 4),
            Text(_userEmail, style: GoogleFonts.poppins(fontSize: 14, color: textGrey)), // Updated to Poppins
            const SizedBox(height: 30),

            if (isAdmin) 
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen()));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryGreen.withOpacity(0.3), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: primaryGreen, size: 26),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text("Admin Dashboard",
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: primaryGreen), // Updated to Poppins
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: primaryGreen),
                      ],
                    ),
                  ),
                ),
              ),
            
            _buildProfileOption(Icons.history, "History", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
            }),

            _buildProfileOption(Icons.local_shipping_outlined, "Shipping Addresses", () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const ShippingAddressScreen()));
            }),

            _buildProfileOption(Icons.payment_outlined, "Payment Methods", () {}),
            _buildProfileOption(Icons.contact_support_outlined, "Contact Us", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactUsScreen()));
            }),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen, elevation: 0,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, color: Colors.white),
                    const SizedBox(width: 10),
                    Text('Log Out', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)), // Updated to Poppins
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
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
              Expanded(child: Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: textBlack))), // Updated to Poppins
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}