import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RentalServicesScreen extends StatelessWidget {
  const RentalServicesScreen({Key? key}) : super(key: key);

  Future<void> _handleHiring(BuildContext context, String gardenerName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('hiring_requests').add({
        'userId': user?.uid ?? 'anonymous',
        'userEmail': user?.email ?? 'no-email',
        'gardenerName': gardenerName,
        'requestDate': FieldValue.serverTimestamp(),
        'status': 'Pending',
      });

      if (context.mounted) {
        _showSuccessDialog(context, "Your hiring request for $gardenerName has been recorded. They will contact you soon.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Future<void> _handleToolRent(BuildContext context, String toolName, String price) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('tool_rent_requests').add({
        'userId': user?.uid ?? 'anonymous',
        'userEmail': user?.email ?? 'no-email',
        'toolName': toolName,
        'price': price,
        'requestDate': FieldValue.serverTimestamp(),
        'status': 'Pending',
      });

      if (context.mounted) {
        _showSuccessDialog(context, "Your rental request for $toolName has been recorded. Our team will contact you soon.");
      }
    } catch (e) {
      print("Tool Rent Error: $e");
    }
  }

  void _showSuccessDialog(BuildContext context, String message) {
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
              Image.asset(
                'assets/images/done.png',
                height: 35,
                width: 35,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Color(0xFF5B8E55),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Request Sent!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'OK',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF5B8E55),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF5B8E55);
    const lightGreenBg = Color(0xFFE8F5E9);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: lightGreenBg, shape: BoxShape.circle),
                child: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
              ),
            ),
          ),
        ),
        title: Text('Services & Rentals',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, color: Colors.black)),
          const SizedBox(width: 10),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Text('Rent Gardening Tools', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),

          SizedBox(
            height: 230,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('rentals').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Text("Something went wrong");
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primaryGreen));
                }

                final toolDocs = snapshot.data!.docs;

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: toolDocs.length,
                  itemBuilder: (context, index) {
                    var data = toolDocs[index].data() as Map<String, dynamic>;
                    return _buildToolCard(
                      context,
                      data['name'] ?? 'No Name',
                      data['price'] ?? 'Price N/A',
                      data['image'] ?? '',
                      primaryGreen,
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 30),

          Text('Hire Professional Gardeners', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('gardeners').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Text("Something went wrong");
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: primaryGreen));
              }

              final gardenerDocs = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: gardenerDocs.length,
                itemBuilder: (context, index) {
                  var data = gardenerDocs[index].data() as Map<String, dynamic>;
                  return _buildGardenerRow(
                    context,
                    data['name'] ?? 'Unknown',
                    data['skill'] ?? 'Specialist',
                    data['rating'] ?? '5.0',
                    data['image'] ?? '',
                    primaryGreen,
                  );
                },
              );
            },
          ),
        ]),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, String name, String price, String img, Color color) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                img,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                Text(price, style: GoogleFonts.inter(color: color)),

                const SizedBox(height: 6),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleToolRent(context, name, price),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                    ),
                    child: const Text("Rent Now", style: TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGardenerRow(BuildContext context, String name, String skill, String rating, String img, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 30, backgroundImage: NetworkImage(img), backgroundColor: Colors.grey[200]),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(skill, style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          Column(
            children: [
              Row(children: [const Icon(Icons.star, color: Colors.orange, size: 16), Text(rating)]),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: () => _handleHiring(context, name),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                ),
                child: const Text('Hire', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
