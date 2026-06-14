import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final int selectedIndex;
  const CheckoutScreen({Key? key, required this.selectedIndex}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final Color primaryGreen = const Color(0xFF5B8E55);
  final Color lightGreenBg = const Color(0xFFE8F5E9);

  // View Control
  bool isAddressSaved = false;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();

  String selectedPaymentMethod = "Cash on Delivery";

  double get subtotal {
    var item = CartScreen.cartItems[widget.selectedIndex];
    double price = double.tryParse(item['price'].toString()) ?? 0;
    int qty = item['qty'] ?? 1;
    return price * qty;
  }
  double shippingFee = 150.0;
  double get totalAmount => subtotal + shippingFee;

  Future<void> _placeOrder() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      var orderItem = CartScreen.cartItems[widget.selectedIndex];

      await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'item': orderItem,
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

      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            Text("Order Placed!", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Your order has been successfully placed.", textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
              onPressed: () {
                setState(() { CartScreen.cartItems.removeAt(widget.selectedIndex); });
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text("Go to Home", style: GoogleFonts.inter(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFCFB),
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
        title: Text(isAddressSaved ? 'Checkout' : 'Select Address', 
          style: GoogleFonts.inter(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600)
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: isAddressSaved ? _buildOrderSummaryView() : _buildAddressFormView(),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
        child: GestureDetector(
          onTap: () {
            if (!isAddressSaved) {
              if (_nameController.text.isNotEmpty && _addressController.text.isNotEmpty) {
                setState(() => isAddressSaved = true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill address details")));
              }
            } else {
              _placeOrder();
            }
          },
          child: Container(
            height: 55,
            decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.zero),
            alignment: Alignment.center,
            child: Text(isAddressSaved ? 'Place Order' : 'Save Address', 
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Add Shipping Address", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 20),
        _buildTextField("Full Name", _nameController),
        _buildTextField("Phone Number", _phoneController, keyboardType: TextInputType.phone),
        _buildTextField("Pin Code", _pinController, keyboardType: TextInputType.number),
        _buildTextField("Address (Area and Street)", _addressController),
        _buildTextField("City/District/Town", _cityController),
        _buildTextField("State", _stateController),
      ],
    );
  }

  Widget _buildOrderSummaryView() {
    var item = CartScreen.cartItems[widget.selectedIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address Mini Display
        Text("Delivery Address", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.2)), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, color: primaryGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Text("${_nameController.text}\n${_addressController.text}, ${_cityController.text}", 
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700])),
              ),
              GestureDetector(
                onTap: () => setState(() => isAddressSaved = false),
                child: Text("Edit", style: GoogleFonts.inter(color: primaryGreen, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Text("Order Summary", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _buildItemTile(item),
        const SizedBox(height: 30),
        Text("Payment Method", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _buildPaymentOption("Cash on Delivery", Icons.money_outlined),
        _buildPaymentOption("Credit/Debit Card", Icons.credit_card_outlined),
        const SizedBox(height: 30),
        _buildFinalBill(),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryGreen)),
        ),
      ),
    );
  }

  Widget _buildItemTile(Map item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withOpacity(0.1))),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item['image'], width: 60, height: 60, fit: BoxFit.cover)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['name'], style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            Text("Qty: ${item['qty']}", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
          ])),
          Text("Rs. ${subtotal.toStringAsFixed(0)}", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon) {
    bool isSelected = selectedPaymentMethod == title;
    return GestureDetector(
      onTap: () => setState(() => selectedPaymentMethod = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? primaryGreen : Colors.grey.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? primaryGreen.withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? primaryGreen : Colors.black54),
            const SizedBox(width: 15),
            Text(title, style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
            const Spacer(),
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? primaryGreen : Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalBill() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: lightGreenBg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildPriceRow("Subtotal", "Rs. ${subtotal.toStringAsFixed(0)}"),
          _buildPriceRow("Shipping Fee", "Rs. ${shippingFee.toStringAsFixed(0)}"),
          const Divider(height: 25),
          _buildPriceRow("Total Payment", "Rs. ${totalAmount.toStringAsFixed(0)}", isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: GoogleFonts.inter(fontSize: isTotal ? 18 : 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}