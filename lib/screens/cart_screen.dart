import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'checkout_screen.dart';
import 'home_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Color primaryGreen = const Color(0xFF5B8E55);
  final Color lightGreenBg = const Color(0xFFE8F5E9);
  
  int selectedItemIndex = 0; // Figma mein pehla item selected hai

  List<Map<String, dynamic>> cartItems = [
    {"name": "Cactus Red", "price": 200, "qty": 1, "image": "https://images.unsplash.com/photo-1509937528035-ad76254b0356?w=200"},
    {"name": "Cactus Red", "price": 200, "qty": 1, "image": "https://images.unsplash.com/photo-1459156212016-c812468e2115?w=200"},
    {"name": "Cactus Red", "price": 200, "qty": 1, "image": "https://images.unsplash.com/photo-1507290439931-a861b5a38200?w=200"},
    {"name": "Cactus Red", "price": 200, "qty": 1, "image": "https://images.unsplash.com/photo-1614594975525-e45190c55d0b?w=200"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFCFB), // Very light greyish green background
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
          'My Cart', 
          style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, color: Colors.black)),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // 1. Items List (Scrollable Area)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                return _buildFigmaCartItem(index);
              },
            ),
          ),

          // 2. Checkout Button (Positioned at bottom right with limited size)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckoutScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 14),
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Text(
                    'Checkout',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar matching Home Screen (White background)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Container(
          width: 58, height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF5B8E55),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: const Color(0xFF5B8E55).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))],
          ),
          child: const Icon(Icons.crop_free, color: Colors.white, size: 26),
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: Colors.white),
        child: BottomNavigationBar(
          currentIndex: 3, // Cart is at index 3
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: primaryGreen,
          unselectedItemColor: const Color(0xFF999999),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: (index) {
            if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (index) => const HomeScreen()));
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 28), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined, size: 28), label: 'Categories'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline, size: 28), label: 'Rentals'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag, size: 28), label: 'Cart'),
          ],
        ),
      ),
    );
  }

  Widget _buildFigmaCartItem(int index) {
    var item = cartItems[index];
    bool isSelected = selectedItemIndex == index;

    return GestureDetector(
      onTap: () => setState(() => selectedItemIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: Row(
          children: [
            // Image with rounded corners
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(item['image'], width: 85, height: 85, fit: BoxFit.cover),
            ),
            const SizedBox(width: 16),
            
            // Details Area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Price Tag style from Figma
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4EB), // Light orange bg for price
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '\$${item['price']}',
                          style: GoogleFonts.inter(color: Colors.orange[700], fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Quantity Selector (+ 1 -)
                      Text(
                        '+ ${item['qty']} -',
                        style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Radio-style selection circle from Figma
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
                ? Center(child: Container(width: 14, height: 14, decoration: BoxDecoration(color: primaryGreen, shape: BoxShape.circle)))
                : null,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}