import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // Sample Data (Logic untouched as requested)
  final List<Map<String, dynamic>> _addresses = [
    {
      "title": "Home",
      "address": "House #123, Street 5, Phase 6, DHA",
      "city": "Lahore",
      "isDefault": true,
    },
    {
      "title": "Office",
      "address": "Software Park, 4th Floor, Arfa Tower",
      "city": "Lahore",
      "isDefault": false,
    }
  ];

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
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                final addr = _addresses[index];
                return _buildAddressCard(addr, index);
              },
            ),
          ),
          _buildAddButton(),
        ],
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
          ? [BoxShadow(color: primaryGreen.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
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
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: textBlack),
                  ),
                ],
              ),
              if (addr['isDefault'])
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(4)),
                  child: Text("DEFAULT", style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            addr['address'],
            style: GoogleFonts.inter(color: textGrey, fontSize: 14, height: 1.4),
          ),
          Text(
            addr['city'],
            style: GoogleFonts.inter(color: textGrey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionButton(Icons.edit_outlined, "Edit", () {}),
              const SizedBox(width: 20),
              _buildActionButton(Icons.delete_outline, "Delete", () {
                setState(() => _addresses.removeAt(index));
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
          Text(label, style: GoogleFonts.inter(color: textGrey, fontSize: 13, fontWeight: FontWeight.w500)),
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
            backgroundColor: primaryGreen,
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          child: Text(
            'ADD NEW ADDRESS',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  void _showAddAddressSheet() {
    // Local state for the BottomSheet UI
    String selectedCategory = "Home";
    bool isDefaultShipping = false;
    bool isDefaultBilling = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Add New Address", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: textBlack)),
                const SizedBox(height: 20),
                
                _buildFieldWithLabel("Recipient's Name", "Input the real name"),
                const SizedBox(height: 12),
                _buildFieldWithLabel("Phone Number", "Please input Phone Number", keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _buildFieldWithLabel("Region / City / District", "Please input Region/City/District"),
                const SizedBox(height: 12),
                _buildFieldWithLabel("Address", "House no./building/street/area"),
                const SizedBox(height: 12),
                _buildFieldWithLabel("Landmark (Optional)", "Add Additional Info"),
                
                const SizedBox(height: 20),
                Text("Address Category", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: textBlack)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildCategoryOption("Home", selectedCategory == "Home", () {
                      setModalState(() => selectedCategory = "Home");
                    }),
                    const SizedBox(width: 20),
                    _buildCategoryOption("Office", selectedCategory == "Office", () {
                      setModalState(() => selectedCategory = "Office");
                    }),
                  ],
                ),
                
                const SizedBox(height: 20),
                _buildCheckboxRow("Default Shipping Address", isDefaultShipping, (val) {
                  setModalState(() => isDefaultShipping = val!);
                }),
                _buildCheckboxRow("Default Billing Address", isDefaultBilling, (val) {
                  setModalState(() => isDefaultBilling = val!);
                }),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: Text("SAVE ADDRESS", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
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

  // Helper to build Label + TextField with Placeholder
  Widget _buildFieldWithLabel(String label, String placeholder, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textBlack),
        ),
        const SizedBox(height: 6),
        TextField(
          keyboardType: keyboardType,
          cursorColor: primaryGreen,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
            filled: true,
            fillColor: bgGrey,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryOption(String title, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? primaryGreen : Colors.grey, width: 2),
            ),
            child: isSelected ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(color: primaryGreen, shape: BoxShape.circle))) : null,
          ),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.inter(fontSize: 14, color: textBlack)),
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
              width: 24, height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                side: const BorderSide(color: Colors.grey, width: 1.5),
              ),
            ),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.inter(fontSize: 14, color: textGrey)),
          ],
        ),
      ),
    );
  }
}