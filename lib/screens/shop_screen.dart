import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';
import 'wishlist_screen.dart';
import 'rental_services_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final Color primaryGreen = const Color(0xFF5B8E55);
  final int _currentIndex = 1;
  String selectedCategory = "All";
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  final List<String> categories = ["All", "Indoor", "Outdoor", "Succulents", "Flowering", "Pots", "Seeds"];

  void _onNavBarTapped(int index) {
    if (index == _currentIndex) return;
    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RentalServicesScreen()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CartScreen()),
      );
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
              Text("Select Category", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 25),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: categories.map((category) {
                  bool isSelected = selectedCategory == category;
                  return ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => selectedCategory = category);
                      Navigator.pop(context);
                    },
                    selectedColor: primaryGreen,
                    backgroundColor: Colors.white,
                    elevation: isSelected ? 4 : 0,
                    pressElevation: 2,
                    shadowColor: Colors.black.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    labelStyle: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? primaryGreen : Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addToCart(Map<String, dynamic> data) async {
    try {
      final cartRef = FirebaseFirestore.instance.collection('cart');
      // Check if product already exists in Firestore cart to avoid duplicate docs
      final existingItems = await cartRef.where('title', isEqualTo: data['title']).limit(1).get();

      String docId;
      if (existingItems.docs.isNotEmpty) {
        // If exists, increment qty in Firestore
        var doc = existingItems.docs.first;
        docId = doc.id;
        await doc.reference.update({'qty': FieldValue.increment(1)});
      } else {
        // If new, add document with qty 1
        DocumentReference docRef = await cartRef.add({
          ...data,
          'qty': 1,
          'addedAt': Timestamp.now(),
        });
        docId = docRef.id;
      }

      // Update local cart state
      CartScreen.addToCart({
        "id": docId,
        "name": data['title'] ?? 'No Title',
        "price": data['price']?.toString() ?? '0',
        "image": data['image'] ?? '',
        "qty": 1,
      });

      if (!mounted) return;
      setState(() {});

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Text(
            "${data['title']} added to cart!",
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: primaryGreen)),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("Error adding to cart: $e");
    }
  }

  Future<void> _toggleFavorite(String productId, Map<String, dynamic> data) async {
    try {
      final wishlistRef = FirebaseFirestore.instance.collection('wishlist').doc(productId);
      final doc = await wishlistRef.get();
      if (doc.exists) {
        await wishlistRef.delete();
      } else {
        await wishlistRef.set(data);
        if (!mounted) return;
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            content: Text(
              "${data['title']} added to your wishlist!",
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.redAccent)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Plant Shop', style: GoogleFonts.poppins(color: const Color(0xFF1A1A1A), fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen())),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('cart').snapshots(),
            builder: (context, snapshot) {
              // Calculate total qty across all items for the badge
              int totalItems = 0;
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  final d = doc.data() as Map<String, dynamic>;
                  totalItems += (d['qty'] as int? ?? 1);
                }
              }
              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, color: Colors.black),
                    if (totalItems > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Center(
                            child: Text(
                              '$totalItems',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(15)),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
                      decoration: InputDecoration(
                          hintText: 'Find your perfect plant...',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: primaryGreen),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 15)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showFilterModal,
                  child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(15)),
                      child: const Icon(Icons.tune, color: Colors.white, size: 24)),
                )
              ],
            ),
          ),
          SizedBox(
            height: 65,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                bool isSelected = selectedCategory == categories[index];
                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = categories[index]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    decoration: BoxDecoration(
                        color: isSelected ? primaryGreen : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isSelected ? 0.1 : 0.03), blurRadius: 5, offset: const Offset(0, 2))]),
                    child: Center(
                        child: Text(categories[index],
                            style: GoogleFonts.poppins(
                                color: isSelected ? Colors.white : Colors.grey.shade600,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                fontSize: 13))),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: primaryGreen));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text("No plants available", style: GoogleFonts.poppins()));

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final category = (data['category'] ?? 'All').toString().trim();
                  return title.contains(searchQuery) && (selectedCategory == "All" || category.toLowerCase() == selectedCategory.toLowerCase());
                }).toList();

                if (docs.isEmpty) return Center(child: Text("No results found in $selectedCategory", style: GoogleFonts.poppins()));

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 18, mainAxisSpacing: 18, childAspectRatio: 0.72),
                  itemCount: docs.length,
                  itemBuilder: (context, index) => _buildPremiumShopCard(docs[index].id, docs[index].data() as Map<String, dynamic>),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, -4)),
            BoxShadow(color: const Color(0xFF000000).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -6)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavBarTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryGreen,
          unselectedItemColor: const Color(0xFF999999),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 28), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined, size: 28), label: 'Categories'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline, size: 28), label: 'Rentals'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined, size: 28), label: 'Cart'),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumShopCard(String productId, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(
                  title: data['title'] ?? 'Plant',
                  imageUrl: data['image'] ?? '',
                  price: data['price']?.toString() ?? '0',
                  description: data['description'] ?? 'No description',
                  subtitle: data['subtitle'] ?? 'Gardening Expert'))),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(margin: const EdgeInsets.all(8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), image: DecorationImage(image: NetworkImage(data['image'] ?? ''), fit: BoxFit.cover))),
                  Positioned(
                    top: 15,
                    right: 15,
                    child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('wishlist').doc(productId).snapshots(),
                        builder: (context, snapshot) {
                          bool isFavorite = snapshot.hasData && snapshot.data!.exists;
                          return GestureDetector(
                            onTap: () => _toggleFavorite(productId, data),
                            child: Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red, size: 18)),
                          );
                        }),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['title'] ?? 'Plant', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF1A1A1A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("\$${data['price'] ?? '0'}", style: GoogleFonts.poppins(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 17)),
                      GestureDetector(
                        onTap: () => _addToCart(data),
                        child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: primaryGreen, shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white, size: 18)),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}