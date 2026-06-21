// detection_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart'; // ✅ PDF Core
import 'package:pdf/widgets.dart' as pw; // ✅ PDF Widgets
import 'package:printing/printing.dart'; // ✅ Printing/Preview

class PlantDetectionScreen extends StatefulWidget {
  const PlantDetectionScreen({Key? key}) : super(key: key);

  @override
  State<PlantDetectionScreen> createState() => _PlantDetectionScreenState();
}

class _PlantDetectionScreenState extends State<PlantDetectionScreen> {
  String _detectedDisease = "Ready to Identify";
  String _confidenceText = "Align the leaf within the frame";
  bool _isLoading = false;

  // Detailed backend response storage
  String _briefInfo = "";
  List<dynamic> _whatToDo = [];
  List<dynamic> _recommendedProducts = [];
  bool _hasResultData = false;
  String _accuracyValue = "";

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

  Future<void> _sendToServer(XFile image) async {
    setState(() {
      _isLoading = true;
      _detectedDisease = "Analyzing...";
      _confidenceText = "Sending to Garden Genie AI";
      _hasResultData = false;
    });

    try {
      var uri = Uri.parse('https://umermoazzam-plantio-backend.hf.space/predict');
      var request = http.MultipartRequest('POST', uri);
      
      final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
      request.fields['userId'] = uid; 

      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String disease = data['disease'] ?? "Unknown";
        String confidence = data['confidence'] != null ? "${data['confidence']}%" : "Scan complete";

        setState(() {
          _detectedDisease = disease;
          _accuracyValue = confidence;
          _briefInfo = data['brief_info'] ?? "No description available.";
          _whatToDo = data['what_to_do'] ?? [];
          _recommendedProducts = data['recommended_products'] ?? [];
          _hasResultData = true;
          _isLoading = false;
        });

        if (uid.isNotEmpty) {
          await FirebaseFirestore.instance.collection('history').add({
            'userId': uid,
            'type': 'scan',
            'title': 'Leaf Diagnosis Result',
            'result': disease,
            'imageUrl': '', 
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } else {
        setState(() {
          _detectedDisease = "Error";
          _isLoading = false;
          _hasResultData = false;
        });
      }
    } catch (e) {
      setState(() {
        _detectedDisease = "Connection Failed";
        _isLoading = false;
        _hasResultData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
              ),
          ),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.1))),
          Positioned(
            top: 50, left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.3),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
            bottom: 160, left: 20, right: 20,
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Disease: $_detectedDisease",
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
                            ),
                            if (!_hasResultData) ...[
                              const SizedBox(height: 4),
                              Text(
                                _confidenceText,
                                style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 13)
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      else if (_hasResultData)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlantResultDetailScreen(
                                  disease: _detectedDisease,
                                  accuracy: _accuracyValue,
                                  info: _briefInfo,
                                  steps: _whatToDo,
                                  products: _recommendedProducts,
                                ),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.8),
                            child: const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 16),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCameraButton(Icons.photo_library, () => _pickImage()),
                const SizedBox(width: 30),
                _buildCameraButton(Icons.camera_alt, () => _pickImage(), isLarge: true),
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

// ✅ NEW APP-THEMED DETAIL SCREEN WITH PDF REPORT GENERATION
class PlantResultDetailScreen extends StatelessWidget {
  final String disease;
  final String accuracy;
  final String info;
  final List<dynamic> steps;
  final List<dynamic> products;

  const PlantResultDetailScreen({
    Key? key,
    required this.disease,
    required this.accuracy,
    required this.info,
    required this.steps,
    required this.products,
  }) : super(key: key);

  // ✅ PDF GENERATION LOGIC
  Future<void> _generatePdfReport(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Plantio Disease Diagnosis Report", 
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 2, color: PdfColors.green),
                pw.SizedBox(height: 20),
                pw.Text("Detected Disease: $disease", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text("Confidence Score: $accuracy", style: pw.TextStyle(fontSize: 14, color: PdfColors.blueGrey700)),
                pw.SizedBox(height: 30),
                pw.Text("About this disease:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text(info, style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 25),
                pw.Text("Recommended Actions:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ...steps.map((s) => pw.Bullet(text: s.toString(), style: const pw.TextStyle(fontSize: 12))),
                pw.SizedBox(height: 25),
                pw.Text("Suggested Products:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text(products.isNotEmpty ? products.join(", ") : "No specific products required.", 
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.green900)),
                pw.Spacer(),
                pw.Divider(),
                pw.Align(alignment: pw.Alignment.center, 
                  child: pw.Text("Report generated by Garden Genie AI - Plantio App", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF5B8E55);
    const darkGreen = Color(0xFF2E5A27);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      // ✅ ADDED FLOATING PDF ACTION BUTTON
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _generatePdfReport(context),
        backgroundColor: darkGreen,
        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
        label: Text("Get Report", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: darkGreen,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                "Diagnosis Result", 
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [darkGreen, primaryColor],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Icon(Icons.eco, size: 80, color: Colors.white.withOpacity(0.2)),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(disease, 
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: darkGreen)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text("Accuracy: $accuracy", 
                            style: GoogleFonts.inter(fontSize: 14, color: primaryColor, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildAppSection(
                    title: "Medical Information", 
                    icon: Icons.menu_book_rounded,
                    content: Text(
                      info.isNotEmpty ? info : "No detailed description available.", 
                      style: GoogleFonts.inter(fontSize: 15, color: Colors.black87, height: 1.6)
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildAppSection(
                    title: "Required Actions", 
                    icon: Icons.fact_check_rounded,
                    content: steps.isEmpty 
                      ? const Text("Observe and monitor for changes.")
                      : Column(
                          children: steps.map((step) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_outline, color: primaryColor, size: 20),
                                const SizedBox(width: 12),
                                Expanded(child: Text(step.toString(), style: GoogleFonts.inter(fontSize: 15, height: 1.4))),
                              ],
                            ),
                          )).toList(),
                        ),
                  ),
                  const SizedBox(height: 20),
                  _buildAppSection(
                    title: "Cure & Solutions", 
                    icon: Icons.local_pharmacy_rounded,
                    content: products.isEmpty
                      ? const Text("Organic prevention is recommended.")
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: products.map((p) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF2E8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryColor.withOpacity(0.2)),
                            ),
                            child: Text(p.toString(), style: GoogleFonts.inter(color: darkGreen, fontWeight: FontWeight.w600, fontSize: 13)),
                          )).toList(),
                        ),
                  ),
                  const SizedBox(height: 80), // Extra space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSection({required String title, required IconData icon, required Widget content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF5B8E55), size: 22),
              const SizedBox(width: 10),
              Text(title, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
          content,
        ],
      ),
    );
  }
}