import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'checkout_screen.dart'; 

class ShippingAddressScreen extends StatefulWidget {
  // ✅ CHANGE: cartItemIndex ko optional (?) bana diya taake Profile se aate waqt error na aaye
  final int? cartItemIndex; 
  const ShippingAddressScreen({Key? key, this.cartItemIndex}) : super(key: key);

  @override
  State<ShippingAddressScreen> createState() => _ShippingAddressScreenState();
}

class _ShippingAddressScreenState extends State<ShippingAddressScreen> {
  // Theme Colors
  final Color primaryGreen = const Color(0xFF5B8E55);
  final Color textBlack = const Color(0xFF1A1A1A);
  final Color textGrey = const Color(0xFF666666);
  final Color bgGrey = const Color(0xFFF5F5F5);

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fullAddressController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();

  String? mongoUserId;
  bool _isInitialLoading = true;
  
  // Selection track karne ke liye variables
  String? selectedAddressId;
  Map<String, dynamic>? selectedAddressData;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  void _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      mongoUserId = prefs.getString('userId');
      _isInitialLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _fullAddressController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _showSuccessDialog(String message) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actionsAlignment: MainAxisAlignment.center,
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textBlack),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", 
              style: GoogleFonts.poppins(color: primaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> addr) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actionsAlignment: MainAxisAlignment.center,
        title: Text(
          "Delete Address",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          "Are you sure you want to delete this address?",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 14, color: textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("NO", 
              style: GoogleFonts.poppins(color: textGrey, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 20),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (mongoUserId != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(mongoUserId)
                    .update({
                  'addresses': FieldValue.arrayRemove([addr])
                });
                _showSuccessDialog("Address deleted successfully");
              }
            },
            child: Text("YES", 
              style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
          style: GoogleFonts.poppins(color: textBlack, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isInitialLoading
                ? const Center(child: CircularProgressIndicator())
                : (mongoUserId == null)
                    ? const Center(child: Text("Please Login to see addresses"))
                    : StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(mongoUserId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return _buildNoAddressFound();
                          }

                          var userData = snapshot.data!.data() as Map<String, dynamic>?;
                          List<dynamic> addresses = userData?['addresses'] ?? [];

                          if (addresses.isEmpty) {
                            return _buildNoAddressFound();
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: addresses.length,
                            itemBuilder: (context, index) {
                              var addr = addresses[index] as Map<String, dynamic>;
                              bool isSelected = selectedAddressId == addr['id'];

                              return GestureDetector(
                                onTap: () {
                                  // Selection sirf tab kaam kare jab checkout flow ho
                                  if (widget.cartItemIndex != null) {
                                    setState(() {
                                      selectedAddressId = addr['id'];
                                      selectedAddressData = addr;
                                    });
                                  }
                                },
                                child: _buildAddressCard(addr, index, isSelected),
                              );
                            },
                          );
                        },
                      ),
          ),
          
          if (!_isInitialLoading && mongoUserId != null) 
            Column(
              children: [
                _buildAddButton(),
                // ✅ CHANGE: Continue button sirf tab dikhega jab cartItemIndex null NAHI hoga
                if (widget.cartItemIndex != null) _buildContinueButton(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNoAddressFound() {
    return Center(
      child: Text(
        "No saved addresses found.",
        style: GoogleFonts.poppins(color: textGrey),
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> addr, int index, bool isSelected) {
    // Agar profile se aaye hain toh selection highlight nahi dikhana
    bool canSelect = widget.cartItemIndex != null;
    bool showHighlight = canSelect && (isSelected || (selectedAddressId == null && (addr['isDefault'] ?? false)));
    
    if (canSelect && selectedAddressId == null && (addr['isDefault'] ?? false)) {
      Future.delayed(Duration.zero, () {
        setState(() {
          selectedAddressId = addr['id'];
          selectedAddressData = addr;
        });
      });
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: showHighlight ? Colors.white : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: showHighlight ? primaryGreen : Colors.transparent,
          width: 2.0, 
        ),
        boxShadow: showHighlight
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
                    addr['category'] == 'Home' ? Icons.home_outlined : Icons.work_outline,
                    color: primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    addr['category'] ?? "Address",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 16, color: textBlack),
                  ),
                ],
              ),
              if (showHighlight)
                Icon(Icons.check_circle, color: primaryGreen, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            addr['fullName'] ?? "",
            style: GoogleFonts.poppins(color: textBlack, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Text(
            addr['fullAddress'] ?? "",
            style: GoogleFonts.poppins(color: textGrey, fontSize: 14, height: 1.4),
          ),
          Text(
            "Phone: ${addr['phone']}",
            style: GoogleFonts.poppins(color: textGrey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionButton(Icons.edit_outlined, "Edit", () {
                _showAddAddressSheet(existingAddress: addr);
              }),
              const SizedBox(width: 20),
              _buildActionButton(Icons.delete_outline, "Delete", () {
                _confirmDelete(addr);
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
              style: GoogleFonts.poppins(
                  color: textGrey, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
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
          ),
          child: Text(
            '+ NEW ADDRESS',
            style: GoogleFonts.poppins(
                color: primaryGreen,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: selectedAddressData == null ? null : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CheckoutScreen(
                  selectedIndex: widget.cartItemIndex!,
                  selectedAddress: selectedAddressData!, 
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedAddressData != null ? primaryGreen : Colors.grey,
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          child: Text(
            'CONTINUE TO SUMMARY',
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  void _showAddAddressSheet({Map<String, dynamic>? existingAddress}) {
    bool isEdit = existingAddress != null;

    if (isEdit) {
      _nameController.text = existingAddress['fullName'] ?? "";
      _phoneController.text = existingAddress['phone'] ?? "";
      _fullAddressController.text = existingAddress['fullAddress'] ?? "";
      _zipController.text = existingAddress['zipCode'] ?? "";
    } else {
      _nameController.clear();
      _phoneController.clear();
      _fullAddressController.clear();
      _zipController.clear();
    }

    String selectedCategory = isEdit ? (existingAddress['category'] ?? "Home") : "Home";
    bool isDefaultShipping = isEdit ? (existingAddress['isDefault'] ?? false) : false;

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
                Text(isEdit ? "Update Address" : "Add New Address",
                    style: GoogleFonts.poppins(
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
                    style: GoogleFonts.poppins(
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
                      if (mongoUserId == null) return;
                      if (_nameController.text.isEmpty || _fullAddressController.text.isEmpty) return;

                      try {
                        Map<String, dynamic> newAddress = {
                          'id': isEdit ? existingAddress['id'] : DateTime.now().millisecondsSinceEpoch.toString(),
                          'fullName': _nameController.text.trim(),
                          'phone': _phoneController.text.trim(),
                          'fullAddress': _fullAddressController.text.trim(),
                          'zipCode': _zipController.text.trim(),
                          'category': selectedCategory,
                          'isDefault': isDefaultShipping,
                          'createdAt': isEdit ? existingAddress['createdAt'] : Timestamp.now(),
                        };

                        var docRef = FirebaseFirestore.instance.collection('users').doc(mongoUserId);

                        if (isEdit) {
                          await docRef.update({
                            'addresses': FieldValue.arrayRemove([existingAddress])
                          });
                        }
                        
                        await docRef.update({
                          'addresses': FieldValue.arrayUnion([newAddress])
                        });

                        Navigator.pop(context); 
                        _showSuccessDialog(isEdit ? "Address Updated!" : "Address Added!");

                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: Text(isEdit ? "UPDATE ADDRESS" : "SAVE ADDRESS",
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
      style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w600, color: textBlack),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: textGrey, size: 20),
        hintText: placeholder,
        hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: bgGrey,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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
              border: Border.all(color: isSelected ? primaryGreen : Colors.grey.shade400, width: 2),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(color: primaryGreen, shape: BoxShape.circle)))
                : null,
          ),
          const SizedBox(width: 10),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: textBlack)),
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
                style: GoogleFonts.poppins(
                    fontSize: 14, color: textGrey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}