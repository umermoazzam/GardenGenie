// product_details_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cart_screen.dart';

class ProductDetailsScreen extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String price;
  final String description;
  final String subtitle;

  const ProductDetailsScreen({
    Key? key,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.description,
    required this.subtitle,
  }) : super(key: key);

  // Updated Function: Success Dialog (Manual Navigation Only)
  void _showAddedToCartDialog(BuildContext context) {
    const primaryGreen = Color(0xFF5B8E55);
    
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1), 
                  shape: BoxShape.circle
                ),
                child: const Icon(Icons.check_circle_outline, color: primaryGreen, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                'Added to Cart!', 
                textAlign: TextAlign.center, 
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)
              ),
              const SizedBox(height: 12),
              Text(
                'The item has been successfully added.', 
                textAlign: TextAlign.center, 
                style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF666666), height: 1.4)
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); 
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
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

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF5B8E55);
    const shadedBackground = Color(0xFFF9F9F9); // White shaded background effect

    return Scaffold(
      backgroundColor: shadedBackground,
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  expandedHeight: MediaQuery.of(context).size.height * 0.45,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.black26,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(imageUrl, fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32), 
                  topRight: Radius.circular(32)
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  )
                ]
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(30, 35, 30, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A), letterSpacing: -0.5)),
                              const SizedBox(height: 4),
                              Text(subtitle, style: GoogleFonts.poppins(fontSize: 14, color: primaryGreen, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text('Description', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                    const SizedBox(height: 10),
                    Text(
                      description, 
                      style: GoogleFonts.poppins(
                        fontSize: 15, 
                        color: const Color(0xFF666666), 
                        height: 1.6, 
                        fontWeight: FontWeight.w400
                      )
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Shaded Bottom Action Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Price', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                        Text('Rs. $price', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        CartScreen.addToCart({
                          "name": title,
                          "price": price,
                          "qty": 1,
                          "image": imageUrl,
                        });
                        _showAddedToCartDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        elevation: 0,
                      ),
                      child: Text('ADD TO CART', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}