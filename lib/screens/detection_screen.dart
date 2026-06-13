import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Added for history saving
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Added for userId

class PlantDetectionScreen extends StatefulWidget {
  const PlantDetectionScreen({Key? key}) : super(key: key);

  @override
  State<PlantDetectionScreen> createState() => _PlantDetectionScreenState();
}

class _PlantDetectionScreenState extends State<PlantDetectionScreen> {
  String _detectedDisease = "Ready to Scan";
  String _confidenceText = "Align the leaf within the frame";
  bool _isLoading = false;

  void _showPermissionDenied() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Permission denied. Please enable it in settings to proceed."),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

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
                  var status = await Permission.camera.request();
                  if (status.isGranted) {
                    final image = await picker.pickImage(source: ImageSource.camera);
                    if (image != null) {
                      _sendToServer(image);
                    }
                  } else {
                    _showPermissionDenied();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF5B8E55)),
                title: const Text("Choose from Gallery"),
                onTap: () async {
                  Navigator.pop(context);
                  var status = await Permission.photos.request();
                  if (status.isGranted || status.isLimited) {
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      _sendToServer(image);
                    }
                  } else {
                    _showPermissionDenied();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- UPDATED BACKEND FUNCTION TO SAVE TO HISTORY ---
  Future<void> _sendToServer(XFile image) async {
    setState(() {
      _isLoading = true;
      _detectedDisease = "Analyzing...";
      _confidenceText = "Sending to Garden Genie AI";
    });

    try {
      var uri = Uri.parse('https://umermoazzam-plantio-backend.hf.space/predict');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String disease = data['disease'] ?? "Unknown";
        String confidence = data['confidence'] != null ? "${data['confidence']}%" : "Scan complete";

        setState(() {
          _detectedDisease = disease;
          _confidenceText = "Confidence: $confidence";
          _isLoading = false;
        });

        // ✅ AUTO-SAVE TO FIREBASE HISTORY
        final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
        await FirebaseFirestore.instance.collection('history').add({
          'userId': uid,
          'type': 'scan',
          'title': 'Leaf Diagnosis Result',
          'result': disease,
          'imageUrl': '', // Placeholder as image is not uploaded to cloud storage yet
          'timestamp': FieldValue.serverTimestamp(),
        });

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
        _confidenceText = "Please check your internet link.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: Image.network(
                'https://images.unsplash.com/photo-1545241047-6083a3684587?w=1200',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.1)),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.3),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
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
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: const DecorationImage(
                            image: NetworkImage('https://images.unsplash.com/photo-1459156212016-c812468e2115?w=200'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Detected: $_detectedDisease",
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            Text(_confidenceText,
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      else
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.8),
                          child: const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 16),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCameraButton(Icons.photo_library, () => _pickImage()),
                const SizedBox(width: 30),
                _buildCameraButton(Icons.camera_alt, () => _pickImage(), isLarge: true),
                const SizedBox(width: 30),
                _buildCameraButton(Icons.flash_on, () {}),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCameraButton(IconData icon, VoidCallback onTap, {bool isLarge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isLarge ? 20 : 12),
        decoration: BoxDecoration(
          color: isLarge ? const Color(0xFF5B8E55) : Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: Icon(icon, color: Colors.white, size: isLarge ? 30 : 24),
      ),
    );
  }
}