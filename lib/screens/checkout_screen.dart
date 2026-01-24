import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final Color primaryGreen = const Color(0xFF5B8E55);
  final Color lightGreenBg = const Color(0xFFE8F5E9);
  
  int selectedPayment = 0; // Default selected as per Figma (My Wallet)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFCFB), // Exact light background from Figma
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
          'Payment Method', // Matching Figma title
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
            // Payment Options based on Screen 25
            _buildFigmaPaymentCard(0, 'My Wallet', Icons.account_balance_wallet_outlined),
            _buildFigmaPaymentCard(1, 'PayPal', Icons.payment_outlined),
            _buildFigmaPaymentCard(3, 'Apple Pay', Icons.apple),
            _buildFigmaPaymentCard(4, 'Cash on Delivery', Icons.money),
            
            const SizedBox(height: 40),

            // Place Order Button (Matching the style of previous screens)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _showSuccessDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: primaryGreen.withOpacity(0.4),
                ),
                child: Text(
                  'Confirm Payment', 
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Exact Card UI from Figma Screen 25
  Widget _buildFigmaPaymentCard(int index, String title, IconData icon) {
    bool isSelected = selectedPayment == index;
    return GestureDetector(
      onTap: () => setState(() => selectedPayment = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
            // Method Name
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
            
            // Selection Circle from Figma
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF5B8E55), size: 80),
            const SizedBox(height: 20),
            Text('Order Placed Successfully!', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Your kitchen gardening journey starts now.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back to Home', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}