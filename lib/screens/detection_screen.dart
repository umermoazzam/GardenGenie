// detection_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'dart:convert'; // JSON parsing ke liye zaroori hai
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class PlantDetectionScreen extends StatefulWidget {
  const PlantDetectionScreen({Key? key}) : super(key: key);

  @override
  State<PlantDetectionScreen> createState() => _PlantDetectionScreenState();
}

class _PlantDetectionScreenState extends State<PlantDetectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isScanning = true;

  // --- UI UPDATE VARIABLES (Change 3) ---
  String _detectedDisease = "Ready to Scan";
  String _confidenceText = "Align the leaf within the frame";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  // --- BOTTOM SHEET FUNCTION (Change 1) ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF5B8E55)),
                title: const Text("Take Photo"),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    _sendToServer(image);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF5B8E55)),
                title: const Text("Choose from Gallery"),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    _sendToServer(image);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- BACKEND FUNCTION (Change 2) ---
  Future<void> _sendToServer(XFile image) async {
    setState(() {
      _isLoading = true;
      _detectedDisease = "Analyzing...";
      _confidenceText = "Sending to Garden Genie AI";
    });

    try {
      var uri = Uri.parse('https://semipublic-monopoly-lorina.ngrok-free.dev/predict');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _detectedDisease = data['disease'] ?? "Unknown";
          // Agar confidence backend se aa raha hai toh dikhao, warna empty rakho
          _confidenceText = data['confidence'] != null 
              ? "Confidence: ${data['confidence']}%" 
              : "Scan complete";
          _isLoading = false;
        });
        print("Server Response: ${response.body}");
      } else {
        setState(() {
          _detectedDisease = "Error";
          _confidenceText = "Server issue (${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _detectedDisease = "Connection Failed";
        _confidenceText = "Please check your internet/ngrok link.";
        _isLoading = false;
      });
      print("Error: $e");
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: Image.network(
                'https://images.unsplash.com/photo-1545241047-6083a3684587?w=1200',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.1)),
          ),

          // 3. Back Button
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.3),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 4. Scanning Frame & Laser Animation
          Center(
            child: Stack(
              children: [
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.white.withOpacity(0.5), width: 1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),

                // Laser Line
                if (_isScanning)
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: _animationController.value * 280,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5B8E55)
                                    .withOpacity(0.8),
                                blurRadius: 15,
                                spreadRadius: 2,
                              )
                            ],
                            color: const Color(0xFF5B8E55),
                          ),
                        ),
                      );
                    },
                  ),

                _buildCorner(top: -2, left: -2, isTop: true, isLeft: true),
                _buildCorner(top: -2, right: -2, isTop: true, isLeft: false),
                _buildCorner(bottom: -2, left: -2, isTop: false, isLeft: true),
                _buildCorner(bottom: -2, right: -2, isTop: false, isLeft: false),
              ],
            ),
          ),

          // 5. Result Card (UPDATED with Dynamic Variables)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: const DecorationImage(
                            image: NetworkImage(
                                'https://images.unsplash.com/photo-1459156212016-c812468e2115?w=200'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Detected: $_detectedDisease", // REAL RESULT
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                            Text(
                              _confidenceText, // REAL CONFIDENCE
                              style: GoogleFonts.inter(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      else
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.8),
                          child: const Icon(Icons.arrow_forward_ios,
                              color: Colors.black, size: 16),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 6. Camera Controls (Change 3: Updated onTap)
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCameraButton(Icons.photo_library, () {
                  _pickImage(); // Photo library ke liye bhi sheet khulegi
                }),
                const SizedBox(width: 30),
                _buildCameraButton(Icons.camera_alt, () {
                  _pickImage(); // AB YE SHEET KHOLAY GA
                }, isLarge: true),
                const SizedBox(width: 30),
                _buildCameraButton(Icons.flash_on, () {}),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCameraButton(IconData icon, VoidCallback onTap,
      {bool isLarge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isLarge ? 20 : 12),
        decoration: BoxDecoration(
          color:
              isLarge ? const Color(0xFF5B8E55) : Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: Icon(icon,
            color: Colors.white, size: isLarge ? 30 : 24),
      ),
    );
  }

  Widget _buildCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool isTop,
    required bool isLeft,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          border: Border(
            top: isTop && top != null
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            bottom: !isTop && bottom != null
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            left: isLeft && left != null
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            right: !isLeft && right != null
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}