import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final int selectedIndex;
  final Map<String, dynamic> selectedAddress; // ✅ Naya Address Map

  const CheckoutScreen({
    Key? key, 
    required this.selectedIndex, 
    required this.selectedAddress
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final Color primaryGreen = const Color(0xFF5B8E55);
  final Color bgColor = const Color(0xFFF9F9F9); // Premium white shaded background

  bool isAddressSaved = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();

  String selectedPaymentMethod = "Cash on Delivery";

  @override
  void initState() {
    super.initState();
    
    // ✅ Step A: Form skip karke seedha Summary dikhao
    isAddressSaved = true; 

    // ✅ Step B: Controllers ko piche se aaye hue address se bhar dein
    _nameController.text = widget.selectedAddress['fullName'] ?? "";
    _phoneController.text = widget.selectedAddress['phone'] ?? "";
    _addressController.text = widget.selectedAddress['fullAddress'] ?? "";
    _pinController.text = widget.selectedAddress['zipCode'] ?? ""; // Mapping from shipping_address_screen
    _cityController.text = widget.selectedAddress['city'] ?? "";
    _stateController.text = widget.selectedAddress['state'] ?? "";
  }

  double get subtotal {
    var item = CartScreen.cartItems[widget.selectedIndex];
    double price = double.tryParse(item['price'].toString()) ?? 0;
    int qty = item['qty'] ?? 1;
    return price * qty;
  }
  double shippingFee = 150.0;
  double get totalAmount => subtotal + shippingFee;

  void _showOrderSuccessDialog() {
    final targetIndex = widget.selectedIndex;

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1), 
                  shape: BoxShape.circle
                ),
                child: const Icon(Icons.local_shipping, color: Color(0xFF5B8E55), size: 40),               
              ),
              const SizedBox(height: 20),
              Text(
                'Order Placed!', 
                textAlign: TextAlign.center, 
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)
              ),
              const SizedBox(height: 12),
              Text(
                'Your order has been placed successfully.', 
                textAlign: TextAlign.center, 
                style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF666666), height: 1.4)
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    if (CartScreen.cartItems.length > targetIndex) {
                      CartScreen.cartItems.removeAt(targetIndex);
                    }
                    Navigator.pop(dialogContext); 
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text('OK', style: GoogleFonts.poppins(color: primaryGreen, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      String currentUserId = user?.uid ?? "Guest_User_ID"; 
      var orderItem = CartScreen.cartItems[widget.selectedIndex];

      await FirebaseFirestore.instance.collection('orders').add({
        'userId': currentUserId,
        'customerName': _nameController.text,
        'customerPhone': _phoneController.text,
        'itemName': orderItem['name'],
        'itemImage': orderItem['image'],
        'itemQty': orderItem['qty'],
        'totalAmount': totalAmount, 
        'paymentMethod': selectedPaymentMethod,
        'status': 'Pending',
        'orderDate': FieldValue.serverTimestamp(),
        'shippingAddress': {
          'fullName': _nameController.text,
          'phone': _phoneController.text,
          'pinCode': _pinController.text,
          'address': _addressController.text,
          'city': _cityController.text,
          'state': _stateController.text,
        }
      });
      _showOrderSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showValidationErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            "Please fill all address details",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[700]),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "OK",
                style: GoogleFonts.poppins(color: primaryGreen, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () {
            if (isAddressSaved) {
              setState(() => isAddressSaved = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(isAddressSaved ? 'Order Summary' : 'Shipping Address', 
          style: GoogleFonts.poppins(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: isAddressSaved ? _buildOrderSummaryView() : _buildAddressFormView(),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
        color: Colors.white,
        child: GestureDetector(
          onTap: () {
            if (!isAddressSaved) {
              if (_nameController.text.trim().isNotEmpty && 
                  _addressController.text.trim().isNotEmpty && 
                  _phoneController.text.trim().isNotEmpty &&
                  _pinController.text.trim().isNotEmpty &&
                  _cityController.text.trim().isNotEmpty &&
                  _stateController.text.trim().isNotEmpty) {
                setState(() => isAddressSaved = true);
              } else {
                _showValidationErrorDialog();
              }
            } else {
              _placeOrder();
            }
          },
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              color: primaryGreen, 
              borderRadius: BorderRadius.zero,
              boxShadow: [
                BoxShadow(color: primaryGreen.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
            alignment: Alignment.center,
            child: Text(isAddressSaved ? 'CONFIRM & PLACE ORDER' : 'SAVE ADDRESS', 
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 1)),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Where should we deliver?", 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)
        ),
        const SizedBox(height: 6),
        Text("Please enter your precise delivery location", 
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])
        ),
        const SizedBox(height: 30),
        _buildTextField("Full Name", _nameController, icon: Icons.person_outline),
        _buildTextField("Phone Number", _phoneController, keyboardType: TextInputType.phone, icon: Icons.phone_android_outlined),
        _buildTextField("Pin Code", _pinController, keyboardType: TextInputType.number, icon: Icons.pin_drop_outlined),
        _buildTextField("Address (Area and Street)", _addressController, icon: Icons.home_outlined),
        _buildTextField("City", _cityController, icon: Icons.location_city_outlined),
        _buildTextField("State", _stateController, icon: Icons.map_outlined),
      ],
    );
  }

  Widget _buildOrderSummaryView() {
    var item = CartScreen.cartItems[widget.selectedIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Delivery Details", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, color: primaryGreen, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_nameController.text, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text("${_addressController.text}, ${_cityController.text}, ${_stateController.text} - ${_pinController.text}", 
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700], height: 1.5)),
                    Text("Phone: ${_phoneController.text}", style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700])),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => isAddressSaved = false),
                child: Text("Edit", style: GoogleFonts.poppins(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Text("Item Details", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _buildItemTile(item),
        const SizedBox(height: 30),
        Text("Payment Method", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _buildPaymentOption("Cash on Delivery", Icons.payments_outlined),
        _buildPaymentOption("Online Payment", Icons.account_balance_wallet_outlined),
        const SizedBox(height: 30),
        _buildFinalBill(),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87), 
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, color: primaryGreen, size: 20) : null,
            labelText: label,
            labelStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryGreen.withOpacity(0.5), width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemTile(Map item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
      ),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(item['image'], width: 55, height: 55, fit: BoxFit.cover)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
            Text("Quantity: ${item['qty']}", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
          ])),
          Text("Rs. ${subtotal.toStringAsFixed(0)}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon) {
    bool isSelected = selectedPaymentMethod == title;
    return GestureDetector(
      onTap: () => setState(() => selectedPaymentMethod = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          border: Border.all(color: isSelected ? primaryGreen : Colors.transparent, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? primaryGreen : Colors.black54, size: 22),
            const SizedBox(width: 15),
            Text(title, style: GoogleFonts.poppins(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 14)),
            const Spacer(),
            Icon(isSelected ? Icons.check_circle : Icons.radio_button_off, color: isSelected ? primaryGreen : Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalBill() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)]
      ),
      child: Column(
        children: [
          _buildPriceRow("Subtotal", "Rs. ${subtotal.toStringAsFixed(0)}"),
          const SizedBox(height: 10),
          _buildPriceRow("Shipping Fee", "Rs. ${shippingFee.toStringAsFixed(0)}"),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(thickness: 1),
          ),
          _buildPriceRow("Total Amount", "Rs. ${totalAmount.toStringAsFixed(0)}", isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.w500, color: isTotal ? Colors.black : Colors.grey[700])),
        Text(value, style: GoogleFonts.poppins(fontSize: isTotal ? 18 : 14, fontWeight: FontWeight.bold, color: isTotal ? primaryGreen : Colors.black)),
      ],
    );
  }
}