import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RentalServicesScreen extends StatelessWidget {
  const RentalServicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF5B8E55);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text('Services & Rentals', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryGreen, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Rent Tools Section (Horizontal)
            Text('Rent Gardening Tools', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildToolCard("Lawn Mower", "Rs. 500/day", "https://images.unsplash.com/photo-1592419044706-39796d40f98c?w=400", primaryGreen),
                  _buildToolCard("Chainsaw", "Rs. 800/day", "https://images.unsplash.com/photo-1590856029826-c7a73142bbf1?w=400", primaryGreen),
                  _buildToolCard("Shovel Set", "Rs. 200/day", "https://images.unsplash.com/photo-1617576683096-00fc8eecb3af?w=400", primaryGreen),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 2. Hire Professionals Section (Requirement VI)
            Text('Hire Professional Gardeners', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildGardenerRow("Mohammad Ali", "Expert in Kitchen Gardening", "4.8", "https://images.unsplash.com/photo-1540331547168-8b63109225b7?w=200", primaryGreen),
            _buildGardenerRow("Sajid Khan", "Landscape & Lawn Specialist", "4.5", "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200", primaryGreen),
            _buildGardenerRow("Ahmed Raza", "Plant Disease Expert", "4.9", "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200", primaryGreen),
          ],
        ),
      ),
    );
  }

  // Tool Card UI
  Widget _buildToolCard(String name, String price, String img, Color color) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Image.network(img, fit: BoxFit.cover, width: double.infinity))),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(price, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Gardener Row UI
  Widget _buildGardenerRow(String name, String skill, String rating, String img, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 30, backgroundImage: NetworkImage(img)),
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
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Hire', style: TextStyle(color: Colors.white, fontSize: 12)),
              )
            ],
          )
        ],
      ),
    );
  }
}