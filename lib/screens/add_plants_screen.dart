import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddPlantScreen extends StatefulWidget {
  final String? docId; 
  final Map<String, dynamic>? plantData; 

  const AddPlantScreen({Key? key, this.docId, this.plantData}) : super(key: key);

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final Color primaryGreen = const Color(0xFF5B8E55);
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _freqController = TextEditingController();

  XFile? _pickedFile;
  bool _isLoading = false;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.plantData != null) {
      _nameController.text = widget.plantData!['name']?.toString() ?? '';
      _typeController.text = widget.plantData!['species']?.toString() ?? '';
      _locationController.text = widget.plantData!['location']?.toString() ?? '';
      _freqController.text = widget.plantData!['wateringFrequency']?.toString() ?? '1';
    }
  }

  Future<void> _getImage() async {
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _pickedFile = file);
  }

  Future<void> _showErrorDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
              const SizedBox(height: 15),
              Text("Incomplete", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              Text("Please fill all details to continue.", style: GoogleFonts.poppins()),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK", style: TextStyle(color: primaryGreen)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _savePlant() async {
    if (_nameController.text.isEmpty || (_pickedFile == null && widget.docId == null)) {
      _showErrorDialog();
      return;
    }

    setState(() => _isLoading = true);
    String? imageUrl = widget.plantData?['imageUrl'];

    try {
      if (_pickedFile != null) {
        String apiKey = "07eb6a84c9b0110403a0fb43dc6a7198";
        var request = http.MultipartRequest('POST', Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'));
        var bytes = await _pickedFile!.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: _pickedFile!.name));
        var response = await request.send();
        var responseData = await response.stream.bytesToString();
        imageUrl = json.decode(responseData)['data']['url'];
      }

      final prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('userId') ?? "guest_user";

      Map<String, dynamic> data = {
        'ownerId': userId,
        'name': _nameController.text,
        'species': _typeController.text,
        'location': _locationController.text,
        'wateringFrequency': int.tryParse(_freqController.text) ?? 1,
        'imageUrl': imageUrl ?? '',
        'lastWatered': widget.plantData?['lastWatered'] ?? FieldValue.serverTimestamp(),
      };

      if (widget.docId == null) {
        await FirebaseFirestore.instance.collection('user_plants').add(data);
      } else {
        await FirebaseFirestore.instance.collection('user_plants').doc(widget.docId).update(data);
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.docId != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8), 
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryGreen))
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(text: TextSpan(style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w800, height: 1.2), children: [
                  TextSpan(text: isEdit ? "Update\n" : "Add New\n", style: const TextStyle(color: Colors.black)),
                  TextSpan(text: "Plant", style: TextStyle(color: primaryGreen)),
                ])),
                const SizedBox(height: 35),
                Center(
                  child: GestureDetector(
                    onTap: _getImage,
                    child: Container(
                      height: 140, width: 140,
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(30), 
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                        border: Border.all(color: Colors.white, width: 2)
                      ),
                      child: _pickedFile == null && !isEdit
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded, color: primaryGreen, size: 35),
                              const SizedBox(height: 8),
                              Text("Photo", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600))
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: _pickedFile != null 
                              ? (kIsWeb ? Image.network(_pickedFile!.path, fit: BoxFit.cover) : Image.network(_pickedFile!.path, fit: BoxFit.cover))
                              : Image.network(widget.plantData?['imageUrl'] ?? '', fit: BoxFit.cover),
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                _buildShadedTextField(_nameController, "Name Of The Plant", Icons.eco_outlined),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: _buildShadedTextField(_typeController, "Species", Icons.category_outlined)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildShadedTextField(_locationController, "Location", Icons.place_outlined)),
                ]),
                const SizedBox(height: 20),
                _buildShadedTextField(_freqController, "Water every (days)", Icons.water_drop_outlined, isNumber: true),
                const SizedBox(height: 45),
                Center(
                  child: Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: primaryGreen.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _savePlant,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 0
                      ),
                      child: Text(isEdit ? "UPDATE PLANT" : "ADD TO GARDEN", style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
    );
  }

  Widget _buildShadedTextField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20, color: primaryGreen.withOpacity(0.7)),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w400),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.white),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: primaryGreen.withOpacity(0.5), width: 1.5),
          ),
        ),
      ),
    );
  }
}