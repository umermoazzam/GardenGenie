// admin_screen.dart
import 'dart:io';
import 'package:http/http.dart' as http; 
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // Date formatting ke liye

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
      setState(() { _selectedImage = File(pickedFile.path); });
    }
  }

  // Status update logic
  void _updateRequestStatus(String docId, String newStatus) async {
    await FirebaseFirestore.instance.collection('hiring_requests').doc(docId).update({
      'status': newStatus,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Request $newStatus!", 
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  Future<void> _publishProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields!", textAlign: TextAlign.center)),
      );
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

      _nameController.clear(); _descController.clear(); _categoryController.clear(); _priceController.clear();
      setState(() { _selectedImage = null; _isUploading = false; _currentView = "Dashboard"; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product Added Successfully!", textAlign: TextAlign.center)),
      );
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e", textAlign: TextAlign.center)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        elevation: 0, backgroundColor: Colors.white, centerTitle: true,
        title: Text(_currentView == "Dashboard" ? "Admin Control Panel" : _currentView,
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18)),
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
      case "Service Requests": return _buildServiceRequestsList();
      default: return _buildMainDashboard();
    }
  }

  Widget _buildMainDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Platform Overview", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('hiring_requests').where('requestType', isEqualTo: 'tool').snapshots(),
                builder: (context, snapshot) {
                  String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";
                  return Expanded(child: _buildStatCard("Tool Requests", count, Icons.handyman, Colors.blue));
                },
              ),
              const SizedBox(width: 15),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                builder: (context, snapshot) {
                  String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";
                  return Expanded(child: _buildStatCard("Total Orders", count, Icons.shopping_bag, Colors.orange));
                },
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text("Management Modules", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildAdminOption(Icons.event_note, "Service Requests", "Manage Tool Rentals Only", () => setState(() => _currentView = "Service Requests")),
          _buildAdminOption(Icons.add_box_outlined, "Add Product", "Upload new plant", () => setState(() => _currentView = "Add Product")),
          _buildAdminOption(Icons.format_list_bulleted, "Product List", "Manage inventory", () => setState(() => _currentView = "Product List")),
          _buildAdminOption(Icons.shopping_cart_checkout, "Orders", "Manage customer orders", () => setState(() => _currentView = "Orders")),
          const SizedBox(height: 40),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: Text("Logout Admin Session", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('hiring_requests')
          .where('requestType', isEqualTo: 'tool') 
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error loading data", style: GoogleFonts.poppins()));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.green));
        
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(child: Text("No Tool Requests Found", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)));
        }
        
        List<QueryDocumentSnapshot> sortedDocs = List.from(docs);
        sortedDocs.sort((a, b) {
          Timestamp t1 = (a.data() as Map<String, dynamic>)['requestDate'] ?? Timestamp.now();
          Timestamp t2 = (b.data() as Map<String, dynamic>)['requestDate'] ?? Timestamp.now();
          return t2.compareTo(t1);
        });

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            var data = sortedDocs[index].data() as Map<String, dynamic>;
            
            String formattedDate = "No Date Scheduled";
            if (data['scheduledDateTime'] != null) {
              DateTime dt = (data['scheduledDateTime'] as Timestamp).toDate();
              formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
            }
            
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 16),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey[200]!, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data['serviceType'] ?? 'Tool Rental', 
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1A1A1A))
                        ),
                        _statusBadge(data['status'] ?? 'Pending'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 18, color: primaryGreen),
                        const SizedBox(width: 8),
                        Text(
                          "Customer: ${data['userName']}", 
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF555555))
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 18, color: primaryGreen),
                        const SizedBox(width: 8),
                        Text(
                          formattedDate, 
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400, color: const Color(0xFF555555))
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_outlined, size: 18, color: primaryGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Address: ${data['address']}", 
                            style: GoogleFonts.poppins(color: const Color(0xFF777777), fontSize: 13, fontWeight: FontWeight.w400)
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.payments_outlined, size: 18, color: primaryGreen),
                        const SizedBox(width: 8),
                        Text(
                          "Price: Rs. ${data['estimatedPrice']}", 
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: primaryGreen)
                        ),
                      ],
                    ),
                    const Divider(height: 30, thickness: 1),
                    
                    if (data['status'] == 'Pending')
                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              "Confirm", 
                              primaryGreen, 
                              () => _updateRequestStatus(sortedDocs[index].id, "Confirmed"),
                              isOutlined: false
                            )
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _actionButton(
                              "Reject", 
                              Colors.redAccent, 
                              () => _updateRequestStatus(sortedDocs[index].id, "Cancelled"),
                              isOutlined: true
                            )
                          ),
                        ],
                      )
                    else if (data['status'] == 'Confirmed')
                      SizedBox(
                        width: double.infinity, 
                        child: _actionButton(
                          "Mark Completed", 
                          primaryGreen, 
                          () => _updateRequestStatus(sortedDocs[index].id, "Completed"),
                          isOutlined: false
                        )
                      )
                    else
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20)
                          ),
                          child: Text(
                            "Booking Closed", 
                            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _actionButton(String title, Color color, VoidCallback onPressed, {required bool isOutlined}) {
    return SizedBox(
      height: 46,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color, width: 1.5),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: Text(
                title, 
                style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 14)
              ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color, 
                elevation: 0,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)
              ),
              child: Text(
                title, 
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
              ),
            ),
    );
  }

  Widget _statusBadge(String status) {
    Color baseColor;
    if (status == 'Confirmed') {
      baseColor = const Color(0xFF2196F3); 
    } else if (status == 'Completed') {
      baseColor = const Color(0xFF4CAF50); 
    } else if (status == 'Cancelled') {
      baseColor = Colors.redAccent;
    } else {
      baseColor = const Color(0xFFFF9800); 
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.12), 
        borderRadius: BorderRadius.circular(30), 
      ),
      child: Text(
        status, 
        style: GoogleFonts.poppins(color: baseColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)
      ),
    );
  }

  Widget _buildOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        List<QueryDocumentSnapshot> sortedDocs = List.from(docs);
        sortedDocs.sort((a, b) {
          Timestamp t1 = (a.data() as Map<String, dynamic>)['orderDate'] ?? Timestamp.now();
          Timestamp t2 = (b.data() as Map<String, dynamic>)['orderDate'] ?? Timestamp.now();
          return t2.compareTo(t1);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            var data = sortedDocs[index].data() as Map<String, dynamic>;
            var addr = data['shippingAddress'] as Map<String, dynamic>? ?? {};
            String orderId = sortedDocs[index].id.substring(0,6).toUpperCase();

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("ORDER: #$orderId", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text(data['status'] ?? 'Pending', style: GoogleFonts.poppins(color: primaryGreen, fontWeight: FontWeight.bold)),
                  ]),
                  const Divider(height: 30),
                  Row(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: data['itemImage'] != null ? Image.network(data['itemImage'], width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s)=>const Icon(Icons.image)) : const Icon(Icons.image)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(data['itemName'] ?? 'Item', style: GoogleFonts.poppins(fontWeight: FontWeight.bold))),
                    Text("Rs. ${data['totalAmount'] ?? 0}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: primaryGreen)),
                  ]),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Customer: ${data['customerName'] ?? 'Guest'}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text("Phone: ${data['customerPhone'] ?? 'N/A'}", style: GoogleFonts.poppins(fontSize: 12)),
                      Text("Address: ${addr['address'] ?? ''}, ${addr['city'] ?? ''}", style: GoogleFonts.poppins(fontSize: 12)),
                    ]),
                  ),
                  Align(
                    alignment: Alignment.centerRight, 
                    child: TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Text(
                                "Confirm Deletion", 
                                textAlign: TextAlign.center, 
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17)
                              ),
                              content: Text(
                                "Are you sure you want to delete Order #$orderId?", 
                                textAlign: TextAlign.center, 
                                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF4A4A4A))
                              ),
                              actionsAlignment: MainAxisAlignment.center, 
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    "Cancel", 
                                    style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w500)
                                  ),
                                ),
                                const SizedBox(width: 8), 
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context); 
                                    await sortedDocs[index].reference.delete(); 
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Order #$orderId has been successfully deleted.", 
                                            textAlign: TextAlign.center, 
                                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500)
                                          ),
                                          backgroundColor: const Color(0xFFF4F4F9), 
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(
                                    "Delete", 
                                    style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      }, 
                      child: Text("Delete Order", style: GoogleFonts.poppins(color: Colors.red))
                    )
                  ),
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
        Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(title, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
      ]),
    );
  }

  Widget _buildAdminOption(IconData icon, String title, String sub, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: primaryGreen),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: GoogleFonts.poppins(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            labelStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13),
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade100, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryGreen.withOpacity(0.6), width: 1.8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddProductForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedImage != null ? primaryGreen.withOpacity(0.3) : Colors.grey.shade200, 
                  width: 1.5
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _selectedImage != null 
                    ? Image.file(_selectedImage!, fit: BoxFit.cover) 
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.add_a_photo_outlined, size: 32, color: primaryGreen),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Upload Product Image", 
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[600])
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField("Product Name", "Enter title", _nameController),
          _buildTextField("Description", "Enter product details", _descController, maxLines: 3),
          Row(
            children: [
              Expanded(child: _buildTextField("Category", "e.g. Seeds, Plants", _categoryController)),
              const SizedBox(width: 14),
              Expanded(child: _buildTextField("Price", "Rs. 0", _priceController)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _publishProduct, 
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen, 
                minimumSize: const Size(double.infinity, 52),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ), 
              child: Text(
                "PUBLISH PRODUCT", 
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.5)
              ),
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.green));
        
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text("No Products Available", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String productTitle = data['title'] ?? 'this product';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: data['image'] != null && data['image'].toString().isNotEmpty
                            ? Image.network(
                                data['image'],
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey[100],
                                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                ),
                              )
                            : Container(
                                width: 70,
                                height: 70,
                                color: Colors.grey[100],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                      ),
                      const SizedBox(width: 16),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: const Color(0xFF2D2D2D),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Rs. ${data['price'] ?? 0}",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 24),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Text(
                                  "Confirm Deletion", 
                                  textAlign: TextAlign.center, 
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17)
                                ),
                                content: Text(
                                  "Are you sure you want to delete \"$productTitle\"?", 
                                  textAlign: TextAlign.center, 
                                  style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF4A4A4A))
                                ),
                                actionsAlignment: MainAxisAlignment.center, 
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      "Cancel", 
                                      style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w500)
                                    ),
                                  ),
                                  const SizedBox(width: 8), 
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context); 
                                      await docs[index].reference.delete(); 
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "\"$productTitle\" has been successfully deleted.", 
                                              textAlign: TextAlign.center, 
                                              style: GoogleFonts.poppins(color: const Color(0xFF2D2D2D), fontWeight: FontWeight.w500)
                                            ),
                                            backgroundColor: const Color(0xFFF4F4F9), 
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        );
                                      }
                                    },
                                    child: Text(
                                      "Delete", 
                                      style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );  
          },
        );
      },
    );
  }
}