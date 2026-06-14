// cart_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'home_screen.dart';
import 'rental_services_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  static List<Map<String, dynamic>> cartItems = [];

  static void addToCart(Map<String, dynamic> item) {
    int index = cartItems.indexWhere((element) => element['name'] == item['name']);
    if (index != -1) {
      cartItems[index]['qty']++;
    } else {
      cartItems.add(item);
    }
  }

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Color primaryGreen = const Color(0xFF5B8E55);
  final Color lightGreenBg = const Color(0xFFE8F5E9);
  
  Set<int> selectedIndices = {0}; 

  List<Map<String, dynamic>> get items => CartScreen.cartItems;

  double _calculateTotal() {
    double total = 0;
    for (int index in selectedIndices) {
      if (index < items.length) {
        double price = double.tryParse(items[index]['price'].toString()) ?? 0;
        int qty = items[index]['qty'] ?? 1;
        total += (price * qty);
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFCFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white, 
        elevation: 0,
        scrolledUnderElevation: 0, 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Cart', 
          style: GoogleFonts.inter(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600)
        ),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, color: Colors.black)),
          const SizedBox(width: 10),
        ],
      ),
      body: items.isEmpty 
          ? Center(child: Text("Your cart is empty", style: GoogleFonts.inter(fontSize: 16, color: Colors.grey)))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _buildFigmaCartItem(index),
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 15, 24, 25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("${selectedIndices.length} Items Selected", style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
                          Text("Rs. ${_calculateTotal().toStringAsFixed(0)}", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          if (selectedIndices.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least one item")));
                            return;
                          }
                          
                          try {
                            List<Map<String, dynamic>> selectedItemsData = selectedIndices.map((i) => items[i]).toList();

                            await FirebaseFirestore.instance.collection('orders').add({
                              'userName': 'Guest User', 
                              'totalPrice': _calculateTotal().toStringAsFixed(0),
                              'items': selectedItemsData,
                              'status': 'Pending',
                              'orderDate': FieldValue.serverTimestamp(),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Placed Successfully!")));

                            setState(() {
                              CartScreen.cartItems.clear();
                              selectedIndices.clear();
                            });
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order Failed: $e")));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.zero),
                          child: Text('Checkout', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      // ✅ Removed Scanner (FloatingActionButton) as requested
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: Colors.white),
        child: BottomNavigationBar(
          currentIndex: 3, 
          type: BottomNavigationBarType.fixed, 
          backgroundColor: Colors.white, 
          elevation: 0,
          selectedItemColor: primaryGreen, 
          unselectedItemColor: const Color(0xFF999999), 
          showSelectedLabels: false, 
          showUnselectedLabels: false,
          onTap: (index) {
            if (index == 0) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
            else if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (context) => const RentalServicesScreen()));
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
    var item = items[index];
    bool isSelected = selectedIndices.contains(index);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) selectedIndices.remove(index);
          else selectedIndices.add(index);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.zero, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
        child: Row(
          children: [
            ClipRRect(borderRadius: BorderRadius.zero, child: Image.network(item['image'], width: 85, height: 85, fit: BoxFit.cover)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'], style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.grey[800])),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFFFF4EB), borderRadius: BorderRadius.circular(8)), child: Text('Rs. ${item['price']}', style: GoogleFonts.inter(color: Colors.orange[700], fontWeight: FontWeight.bold, fontSize: 13))),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          GestureDetector(onTap: () => setState(() { if (item['qty'] > 1) item['qty']--; }), child: Text('-', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14))),
                          const SizedBox(width: 6),
                          Text('${item['qty']}', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14)),
                          const SizedBox(width: 6),
                          GestureDetector(onTap: () => setState(() { item['qty']++; }), child: Text('+', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() { CartScreen.cartItems.removeAt(index); selectedIndices.remove(index); });
              },
              child: Icon(Icons.delete_outline, color: Colors.red[300], size: 24),
            ),
            const SizedBox(width: 12),
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? primaryGreen : Colors.grey.withOpacity(0.3), width: 2)),
              child: isSelected ? Center(child: Container(width: 14, height: 14, decoration: BoxDecoration(color: primaryGreen, shape: BoxShape.circle))) : null,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}