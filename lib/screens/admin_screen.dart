import 'dart:io';
import 'package:http/http.dart' as http; // Added for ImgBB
import 'dart:convert'; // Added for JSON parsing
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final Color primaryGreen = const Color(0xFF5B8E55);
  String _currentView = "Dashboard"; 

  // Controllers for Add Product
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // UPDATED FUNCTION: Uploads to ImgBB instead of Firebase Storage
  Future<void> _publishProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and select an image!"))
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 1. Upload Image to ImgBB (Free & No Card Needed)
      var request = http.MultipartRequest('POST', Uri.parse('https://api.imgbb.com/1/upload'));
      
      // 👇 YAHAN APNI IMGBB WALI API KEY PASTE KAREIN
      request.fields['key'] = '07eb6a84c9b0110403a0fb43dc6a7198'; 
      
      request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);

      if (response.statusCode != 200) {
        throw "Upload failed: ${jsonData['error']['message']}";
      }

      // ImgBB se milne wala direct image link
      String downloadUrl = jsonData['data']['url'];

      // 2. Save Data to Firestore
      await FirebaseFirestore.instance.collection('products').add({
        'title': _nameController.text,
        'description': _descController.text,
        'category': _categoryController.text,
        'price': _priceController.text,
        'image': downloadUrl,
        'isNew': true,
        'subtitle': 'Plantio Verified',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _nameController.clear();
      _descController.clear();
      _categoryController.clear();
      _priceController.clear();
      setState(() {
        _selectedImage = null;
        _isUploading = false;
        _currentView = "Dashboard";
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Added Successfully!")));
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      print("Full Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          _currentView == "Dashboard" ? "Admin Control Panel" : _currentView,
          style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: IconButton(
          icon: Icon(_currentView == "Dashboard" ? Icons.arrow_back_ios : Icons.close, color: Colors.black),
          onPressed: () {
            if (_currentView == "Dashboard") Navigator.pop(context);
            else setState(() => _currentView = "Dashboard");
          },
        ),
      ),
      body: _isUploading 
        ? Center(child: CircularProgressIndicator(color: primaryGreen)) 
        : _buildCurrentBody(),
    );
  }

  Widget _buildCurrentBody() {
    switch (_currentView) {
      case "Add Product": return _buildAddProductForm();
      case "Product List": return _buildProductList();
      case "Orders": return _buildOrdersList();
      default: return _buildMainDashboard();
    }
  }

  Widget _buildMainDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Platform Overview", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          
          Row(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";
                  return _buildStatCard("Total Users", count, Icons.people_alt, Colors.blue);
                },
              ),
              const SizedBox(width: 15),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('sellers').snapshots(),
                builder: (context, snapshot) {
                  String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";
                  return _buildStatCard("Active Sellers", count, Icons.storefront, primaryGreen);
                },
              ),
            ],
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                builder: (context, snapshot) {
                  String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";
                  return _buildStatCard("Total Orders", count, Icons.shopping_bag, Colors.orange);
                },
              ),
              const SizedBox(width: 15),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                builder: (context, snapshot) {
                  double totalRevenue = 0;
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      var data = doc.data() as Map<String, dynamic>;
                      totalRevenue += double.tryParse(data['totalPrice'].toString()) ?? 0;
                    }
                  }
                  String revenueText = snapshot.hasData ? "Rs. ${totalRevenue.toInt()}" : "...";
                  return _buildStatCard("Revenue", revenueText, Icons.account_balance_wallet, Colors.purple);
                },
              ),
            ],
          ),

          const SizedBox(height: 30),
          Text("Management Modules", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildAdminOption(Icons.add_box_outlined, "Add Product", "Upload new plant or gardening tool", () => setState(() => _currentView = "Add Product")),
          _buildAdminOption(Icons.format_list_bulleted, "Product List", "View, Edit and delete inventory", () => setState(() => _currentView = "Product List")),
          _buildAdminOption(Icons.shopping_cart_checkout, "Orders", "Track and manage customer orders", () => setState(() => _currentView = "Orders")),
          const SizedBox(height: 40),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: Text("Logout Admin Session", style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddProductForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Product Image", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _selectedImage != null 
                ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedImage!, fit: BoxFit.cover))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 40),
                      const SizedBox(height: 8),
                      Text("Tap to select image from gallery", style: GoogleFonts.inter(color: Colors.grey)),
                    ],
                  ),
            ),
          ),
          const SizedBox(height: 25),
          _buildTextField("Product Name", "Enter title", _nameController),
          _buildTextField("Product Description", "Enter details", _descController, maxLines: 3),
          Row(
            children: [
              Expanded(child: _buildTextField("Category", "e.g. Seeds", _categoryController)),
              const SizedBox(width: 15),
              Expanded(child: _buildTextField("Price", "Rs. 0", _priceController)),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _publishProduct,
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1))),
              child: Text("ADD PRODUCT", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), image: DecorationImage(image: NetworkImage(data['image']), fit: BoxFit.cover)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(data['title'], style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      Text("Category: ${data['category']}", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                      Text("Rs. ${data['price']}", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: primaryGreen)),
                    ]),
                  ),
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => docs[index].reference.delete()),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').orderBy('orderDate', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("Order #${docs[index].id.substring(0, 5)}", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  Text(data['status'], style: GoogleFonts.inter(fontSize: 12, color: primaryGreen, fontWeight: FontWeight.bold)),
                ]),
                const Divider(height: 25),
                Text("Customer: ${data['userName']}", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 5),
                Text("Total Price: Rs. ${data['totalPrice']}", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: primaryGreen)),
              ]),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
        ]),
      ),
    );
  }

  Widget _buildAdminOption(IconData icon, String title, String sub, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: primaryGreen)),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(sub, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint, fillColor: const Color(0xFFF5F5F5), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
        ),
      ]),
    );
  }
}