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
// Import your Payment Screen here
import 'payment_methods_screen.dart'; 

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
  final Color bgWhiteShade = const Color(0xFFF9F9F9);

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
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            content: Text(
              'Are you sure you want to logout?',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: textGrey)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.redAccent)),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: primaryGreen),
                title: Text('Choose from library', style: GoogleFonts.poppins()),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: primaryGreen),
                title: Text('Take photo', style: GoogleFonts.poppins()),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              ),
              if (_profileImagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text('Remove current picture', style: GoogleFonts.poppins(color: Colors.red)),
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
        title: Text('My Profile', style: GoogleFonts.poppins(color: textBlack, fontSize: 18, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: _showImagePickerOptions,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: bgWhiteShade,
                        backgroundImage: (_profileImagePath != null && File(_profileImagePath!).existsSync())
                            ? FileImage(File(_profileImagePath!)) as ImageProvider
                            : const AssetImage('assets/icons/user.png'),
                      ),
                    ),
                    Positioned(
                      bottom: 4, right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryGreen, 
                          shape: BoxShape.circle, 
                          border: Border.all(color: Colors.white, width: 2)
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(_userName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: textBlack)),
            const SizedBox(height: 4),
            Text(_userEmail, style: GoogleFonts.poppins(fontSize: 14, color: textGrey)),
            const SizedBox(height: 35),

            if (isAdmin) 
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen()));
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: primaryGreen.withOpacity(0.2), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.admin_panel_settings, color: primaryGreen, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text("Admin Dashboard",
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: primaryGreen),
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

            // ✅ CHANGED: Logic added for Payment Methods navigation
            _buildProfileOption(Icons.payment_outlined, "Payment Methods", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()));
            }),
            
            _buildProfileOption(Icons.contact_support_outlined, "Contact Us", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactUsScreen()));
            }),

            const SizedBox(height: 30),

            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              ),
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen, 
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text('Log Out', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.only(bottom: 18.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgWhiteShade,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primaryGreen, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: textBlack))),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}