// admin_screen.dart
import 'dart:io';
import 'package:http/http.dart' as http; 
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final Color primaryGreen = const Color(0xFF5B8E55);
  String _currentView = "Dashboard"; 

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _publishProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields!")));
      return;
    }
    setState(() => _isUploading = true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse('https://api.imgbb.com/1/upload'));
      request.fields['key'] = '07eb6a84c9b0110403a0fb43dc6a7198'; 
      request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);
      if (response.statusCode != 200) throw "Upload failed";

      String downloadUrl = jsonData['data']['url'];
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
      setState(() { _selectedImage = null; _isUploading = false; _currentView = "Dashboard"; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Added Successfully!")));
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        elevation: 0, backgroundColor: Colors.white, centerTitle: true,
        title: Text(_currentView == "Dashboard" ? "Admin Control Panel" : _currentView,
          style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
        leading: IconButton(
          icon: Icon(_currentView == "Dashboard" ? Icons.arrow_back_ios : Icons.close, color: Colors.black),
          onPressed: () {
            if (_currentView == "Dashboard") Navigator.pop(context);
            else setState(() => _currentView = "Dashboard");
          },
        ),
      ),
      body: _isUploading ? Center(child: CircularProgressIndicator(color: primaryGreen)) : _buildCurrentBody(),
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
              // 1. Total Users Card
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  String count = "...";
                  if (snapshot.hasError) {
                    print("Firestore Error: ${snapshot.error}");
                    count = "Check Rules"; 
                  } else if (snapshot.hasData) {
                    count = snapshot.data!.docs.length.toString();
                  }
                  return Expanded(child: _buildStatCard("Total Users", count, Icons.people_alt, Colors.blue));
                },
              ),
              const SizedBox(width: 15),
              // 2. Total Orders Card
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                builder: (context, snapshot) {
                  String count = "...";
                  if (snapshot.hasData) {
                    count = snapshot.data!.docs.length.toString();
                  }
                  return Expanded(child: _buildStatCard("Total Orders", count, Icons.shopping_bag, Colors.orange));
                },
              ),
            ],
          ),
          const SizedBox(height: 15),
          // 3. Revenue Card
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').snapshots(),
            builder: (context, snapshot) {
              double totalRevenue = 0;
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  double val = double.tryParse(data['totalAmount']?.toString() ?? data['totalPrice']?.toString() ?? "0") ?? 0.0;
                  totalRevenue += val;
                }
              }
              return _buildStatCard("Total Revenue Generated", "Rs. ${totalRevenue.toStringAsFixed(0)}", Icons.account_balance_wallet, Colors.purple);
            },
          ),
          const SizedBox(height: 30),
          Text("Management Modules", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildAdminOption(Icons.add_box_outlined, "Add Product", "Upload new plant", () => setState(() => _currentView = "Add Product")),
          _buildAdminOption(Icons.format_list_bulleted, "Product List", "Manage inventory", () => setState(() => _currentView = "Product List")),
          _buildAdminOption(Icons.shopping_cart_checkout, "Orders", "Manage customer orders", () => setState(() => _currentView = "Orders")),
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

  Widget _buildOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').orderBy('orderDate', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return Center(child: Text("No orders found", style: GoogleFonts.inter()));
        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            var addr = data['shippingAddress'] as Map<String, dynamic>? ?? {};
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("ORDER: #${docs[index].id.substring(0,6).toUpperCase()}", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text(data['status'] ?? 'Pending', style: GoogleFonts.inter(color: primaryGreen, fontWeight: FontWeight.bold)),
                  ]),
                  const Divider(height: 30),
                  Row(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: data['itemImage'] != null ? Image.network(data['itemImage'], width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s)=>const Icon(Icons.image)) : const Icon(Icons.image)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(data['itemName'] ?? 'Item', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                    Text("Rs. ${data['totalAmount'] ?? 0}", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: primaryGreen)),
                  ]),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Customer: ${data['customerName'] ?? 'Guest'}", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text("Phone: ${data['customerPhone'] ?? 'N/A'}", style: GoogleFonts.inter(fontSize: 12)),
                      Text("Address: ${addr['address'] ?? ''}, ${addr['city'] ?? ''}", style: GoogleFonts.inter(fontSize: 12)),
                    ]),
                  ),
                  Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => docs[index].reference.delete(), child: const Text("Delete Order", style: TextStyle(color: Colors.red)))),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 12),
        Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(title, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
      ]),
    );
  }

  Widget _buildAdminOption(IconData icon, String title, String sub, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: primaryGreen),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: GoogleFonts.inter(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller, maxLines: maxLines,
        decoration: InputDecoration(labelText: label, hintText: hint, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  Widget _buildAddProductForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity, height: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
            child: _selectedImage != null ? Image.file(_selectedImage!, fit: BoxFit.cover) : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 20),
        _buildTextField("Product Name", "Title", _nameController),
        _buildTextField("Description", "Details", _descController, maxLines: 3),
        Row(children: [
          Expanded(child: _buildTextField("Category", "Seeds", _categoryController)),
          const SizedBox(width: 10),
          Expanded(child: _buildTextField("Price", "0", _priceController)),
        ]),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _publishProduct, style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, minimumSize: const Size(double.infinity, 50)), child: const Text("PUBLISH", style: TextStyle(color: Colors.white))),
      ]),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: Image.network(data['image'] ?? '', width: 50, height: 50, fit: BoxFit.cover),
              title: Text(data['title'] ?? 'N/A'),
              subtitle: Text("Rs. ${data['price'] ?? 0}"),
              trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => snapshot.data!.docs[index].reference.delete()),
            );
          },
        );
      },
    );
  }
}