// checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final int selectedIndex; // ✅ Accept index from CartScreen
  const CheckoutScreen({Key? key, required this.selectedIndex}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final Color primaryGreen = const Color(0xFF5B8E55);
  final Color lightGreenBg = const Color(0xFFE8F5E9);
  
  int selectedPayment = 0; 
  bool isLoading = false;

  String _getPaymentMethodName(int index) {
    switch (index) {
      case 0: return 'My Wallet';
      case 1: return 'PayPal';
      case 3: return 'Apple Pay';
      case 4: return 'Cash on Delivery';
      default: return 'Other';
    }
  }

  // ✅ PROCESS SELECTIVE ORDER: Remove only the checked-out item
  Future<void> _placeOrder() async {
    // Check if the item still exists in cart
    if (CartScreen.cartItems.isEmpty || widget.selectedIndex >= CartScreen.cartItems.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Item not found in cart!")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // ✅ Pick ONLY the selected product
      final selectedProduct = CartScreen.cartItems[widget.selectedIndex];
      
      Map<String, dynamic> orderData = {
        'userId': user?.uid ?? 'anonymous',
        'userEmail': user?.email ?? 'no-email',
        'items': [selectedProduct], // ✅ Only this specific product goes to DB
        'paymentMethod': _getPaymentMethodName(selectedPayment),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Pending',
      };

      // Save to Firebase
      await FirebaseFirestore.instance.collection('orders').add(orderData);

      // ✅ REMOVE ONLY THIS ITEM FROM STATIC CART
      CartScreen.cartItems.removeAt(widget.selectedIndex);

      setState(() => isLoading = false);
      
      if (mounted) _showSuccessDialog(context);

    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error placing order: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFCFB),
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
                decoration: BoxDecoration(
                  color: lightGreenBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
              ),
            ),
          ),
        ),
        title: Text(
          'Payment Method',
          style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, color: Colors.black)),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFigmaPaymentCard(0, 'My Wallet', Icons.account_balance_wallet_outlined),
            _buildFigmaPaymentCard(1, 'PayPal', Icons.payment_outlined),
            _buildFigmaPaymentCard(3, 'Apple Pay', Icons.apple),
            _buildFigmaPaymentCard(4, 'Cash on Delivery', Icons.money),
            
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                  elevation: 5,
                  shadowColor: primaryGreen.withOpacity(0.4),
                ),
                child: isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      'Confirm Payment', 
                      style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFigmaPaymentCard(int index, String title, IconData icon) {
    bool isSelected = selectedPayment == index;
    return GestureDetector(
      onTap: () => setState(() => selectedPayment = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03), 
              blurRadius: 15, 
              offset: const Offset(0, 5)
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title, 
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, 
                  fontSize: 16, 
                  color: Colors.black87
                )
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primaryGreen : Colors.grey.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: isSelected 
                ? Center(
                    child: Container(
                      width: 14, 
                      height: 14, 
                      decoration: BoxDecoration(
                        color: primaryGreen, 
                        shape: BoxShape.circle
                      )
                    )
                  )
                : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
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
                'Order Placed Successfully!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 10),
              Text(
                'Your kitchen gardening journey starts now.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.inter(
                        color: const Color(0xFF5B8E55),
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}