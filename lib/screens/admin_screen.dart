import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  // Theme Color from your Figma requirements
  final Color primaryGreen = const Color(0xFF5B8E55);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Light grey background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          "Admin Control Panel",
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Overview Stats Section (Proposed in your Methodology)
            Text(
              "Platform Overview",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildStatCard("Total Users", "1,240", Icons.people_alt, Colors.blue),
                const SizedBox(width: 15),
                _buildStatCard("Active Sellers", "85", Icons.storefront, primaryGreen),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildStatCard("Total Orders", "452", Icons.shopping_bag, Colors.orange),
                const SizedBox(width: 15),
                _buildStatCard("Revenue", "Rs. 45k", Icons.account_balance_wallet, Colors.purple),
              ],
            ),

            const SizedBox(height: 30),

            // 2. Management Modules (Mapping your Requirements)
            Text(
              "Management Modules",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 15),

            _buildAdminOption(
              context,
              Icons.person_search,
              "User Management",
              "View, Edit, or Remove Buyers",
            ),
            _buildAdminOption(
              context,
              Icons.verified_user,
              "Seller Management",
              "Approve new sellers & verify products",
            ),
            _buildAdminOption(
              context,
              Icons.local_shipping,
              "Global Order Tracking",
              "Track and update status for all orders",
            ),
            _buildAdminOption(
              context,
              Icons.auto_graph,
              "Analytics & Reports",
              "Performance and Sales statistics",
            ),
            _buildAdminOption(
              context,
              Icons.video_library,
              "Content Management",
              "Manage Blogs and Learning Videos",
            ),
            
            const SizedBox(height: 40),
            
            // Logout Button
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text(
                  "Logout Admin Session",
                  style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for Stats Cards (Top Section)
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom Admin Option Widget based on Figma Screen 18 Style
  Widget _buildAdminOption(BuildContext context, IconData icon, String title, String sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryGreen),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          sub,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          // Add navigation to specific management screens here
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Opening $title...")),
          );
        },
      ),
    );
  }
}