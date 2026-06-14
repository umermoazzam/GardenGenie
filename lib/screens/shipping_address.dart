import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShippingAddressScreen extends StatefulWidget {
  const ShippingAddressScreen({Key? key}) : super(key: key);

  @override
  State<ShippingAddressScreen> createState() => _ShippingAddressScreenState();
}

class _ShippingAddressScreenState extends State<ShippingAddressScreen> {
  // Theme Colors (Matching Profile Screen)
  final Color primaryGreen = const Color(0xFF5B8E55);
  final Color textBlack = const Color(0xFF1A1A1A);
  final Color textGrey = const Color(0xFF666666);
  final Color bgGrey = const Color(0xFFF5F5F5);

  // Controllers for Add Address Form
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fullAddressController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _fullAddressController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Shipping Addresses',
          style: GoogleFonts.inter(color: textBlack, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<User?>(
              // 1. Pehle check karo ke user login hai ya nahi (Live Listener)
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, authSnapshot) {
                if (authSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final currentUser = authSnapshot.data;

                if (currentUser == null) {
                  return const Center(child: Text("Please Login to see addresses"));
                }

                // 2. Agar login hai, toh uske addresses fetch karo
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return _buildNoAddressFound();
                    }

                    var userData = snapshot.data!.data() as Map<String, dynamic>;
                    var addressData = userData['address_info'];

                    if (addressData == null) {
                      return _buildNoAddressFound();
                    }

                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _buildAddressCard({
                          "title": addressData['category'] ?? "Home",
                          "address": addressData['fullAddress'] ?? "",
                          "city": addressData['zipCode'] ?? "",
                          "isDefault": addressData['isDefault'] ?? true,
                          "phone": addressData['phone'] ?? "",
                        }, 0),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildNoAddressFound() {
    return Center(
      child: Text(
        "No saved addresses found.",
        style: GoogleFonts.inter(color: textGrey),
      ),
    );
  }

  // Card UI with Icons preserved
  Widget _buildAddressCard(Map<String, dynamic> addr, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: addr['isDefault'] ? Colors.white : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: addr['isDefault'] ? primaryGreen : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: addr['isDefault']
            ? [
                BoxShadow(
                    color: primaryGreen.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    addr['title'] == 'Home' ? Icons.home_outlined : Icons.work_outline,
                    color: primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    addr['title'],
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, fontSize: 16, color: textBlack),
                  ),
                ],
              ),
              if (addr['isDefault'])
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: primaryGreen, borderRadius: BorderRadius.circular(4)),
                  child: Text("DEFAULT",
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            addr['address'],
            style: GoogleFonts.inter(color: textGrey, fontSize: 14, height: 1.4),
          ),
          Text(
            "Phone: ${addr['phone']}",
            style: GoogleFonts.inter(color: textGrey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionButton(Icons.edit_outlined, "Edit", () {}),
              const SizedBox(width: 20),
              _buildActionButton(Icons.delete_outline, "Delete", () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({'address_info': FieldValue.delete()});
                }
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: textGrey),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  color: textGrey, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => _showAddAddressSheet(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            elevation: 0,
            side: BorderSide(color: primaryGreen, width: 0.5),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            overlayColor: Colors.grey.withOpacity(0.1),
          ),
          child: Text(
            '+ NEW ADDRESS',
            style: GoogleFonts.inter(
                color: primaryGreen,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  void _showAddAddressSheet() {
    String selectedCategory = "Home";
    bool isDefaultShipping = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Add New Address",
                    style: GoogleFonts.inter(
                        fontSize: 20, fontWeight: FontWeight.bold, color: textBlack)),
                const SizedBox(height: 25),
                _buildBoldField("Full Name", Icons.person_outline, _nameController),
                const SizedBox(height: 16),
                _buildBoldField("Phone Number", Icons.phone_outlined, _phoneController,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildBoldField("Full Address (House, Street, City)",
                    Icons.location_on_outlined, _fullAddressController),
                const SizedBox(height: 16),
                _buildBoldField("Zip Code", Icons.pin_drop_outlined, _zipController,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 25),
                Text("Address Category",
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.bold, color: textBlack)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildCategoryOption("Home", selectedCategory == "Home", () {
                      setModalState(() => selectedCategory = "Home");
                    }),
                    const SizedBox(width: 25),
                    _buildCategoryOption("Office", selectedCategory == "Office", () {
                      setModalState(() => selectedCategory = "Office");
                    }),
                  ],
                ),
                const SizedBox(height: 25),
                _buildCheckboxRow("Set as Default Address", isDefaultShipping, (val) {
                  setModalState(() => isDefaultShipping = val!);
                }),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      print("--- Save Button Clicked ---"); // Console mein check karein
                      final user = FirebaseAuth.instance.currentUser;
                      
                      if (user == null) {
                        print("Error: User is NULL. App thinks nobody is logged in.");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Error: User not found. Try to Log Out and Log In again."))
                        );
                        return;
                      }

                      print("User found: ${user.uid}. Attempting to save...");

                      try {
                        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                          'address_info': {
                            'fullName': _nameController.text.trim(),
                            'phone': _phoneController.text.trim(),
                            'fullAddress': _fullAddressController.text.trim(),
                            'zipCode': _zipController.text.trim(),
                            'category': "Home",
                            'isDefault': true,
                          }
                        }, SetOptions(merge: true));

                        print("Success: Data saved in Firestore!");
                        
                        // Clear fields before closing
                        _nameController.clear();
                        _phoneController.clear();
                        _fullAddressController.clear();
                        _zipController.clear();

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Address Saved Successfully!")));
                      } catch (e) {
                        print("Firestore Error: $e");
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Firestore Error: $e")));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: Text("SAVE ADDRESS",
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoldField(String placeholder, IconData icon,
      TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      cursorColor: primaryGreen,
      style: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w600, color: textBlack),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: textGrey, size: 20),
        hintText: placeholder,
        hintStyle: GoogleFonts.inter(
            color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: bgGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryGreen.withOpacity(0.5), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }

  Widget _buildCategoryOption(String title, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: isSelected ? primaryGreen : Colors.grey.shade400, width: 2),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                            color: primaryGreen, shape: BoxShape.circle)))
                : null,
          ),
          const SizedBox(width: 10),
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: textBlack)),
        ],
      ),
    );
  }

  Widget _buildCheckboxRow(String label, bool value, Function(bool?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                side: BorderSide(color: Colors.grey.shade400, width: 1.5),
              ),
            ),
            const SizedBox(width: 12),
            Text(label,
                style: GoogleFonts.inter( 
                    fontSize: 14, color: textGrey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}