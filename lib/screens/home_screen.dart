import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'blogs_videos_screen.dart';
import 'rental_services_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'product_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; 

  void _onNavBarTapped(int index) {
    if (index == 0) return;

    if (index == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categories / Shop Screen is currently disabled')),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RentalServicesScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CartScreen()),
      );
    }
  }

  void _navigateToDetails(String title, String imageUrl, String price, String description, String subtitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(
          title: title,
          imageUrl: imageUrl,
          price: price,
          description: description,
          subtitle: subtitle,
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: GoogleFonts.inter(color: const Color(0xFF5B8E55))),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                        children: const [
                          TextSpan(text: 'New on ', style: TextStyle(color: Color(0xFF1A1A1A))),
                          TextSpan(text: 'Plantio', style: TextStyle(color: Color(0xFF5B8E55))),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      },
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey.shade200,
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickActionButton(
                        icon: Icons.water_drop_outlined,
                        label: 'My Garden',
                        onTap: () => Navigator.pushNamed(context, '/my-plants'),
                      ),
                      const SizedBox(width: 20),
                      _buildQuickActionButton(
                        icon: Icons.local_florist_outlined,
                        label: 'My Plants',
                        onTap: () => Navigator.pushNamed(context, '/my-plants'),
                      ),
                      const SizedBox(width: 20),
                      _buildQuickActionButton(
                        icon: Icons.search,
                        label: 'Search',
                        onTap: () {
                          _showInfoDialog(context, "Search", "Search functionality is currently disabled.");
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1606041008023-472dfb5e530f?w=800'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.6)],
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showAIOptionsDialog(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('New in', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                'Create plans\nwith AI Assistant',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('products').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return const Text('Something went wrong');
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF5B8E55)));
                    }

                    final productDocs = snapshot.data!.docs;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: productDocs.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemBuilder: (context, index) {
                        var data = productDocs[index].data() as Map<String, dynamic>;

                        String title = data['title'] ?? 'No Title';
                        String imageUrl = data['image'] ?? '';
                        String price = (data['price'] ?? '0').toString();
                        String description = data['description'] ?? 'No description available for this plant.';
                        bool isNew = data['isNew'] ?? false;
                        String subtitle = data['subtitle'] ?? 'Garden Genie Specialist';

                        return _buildProductCard(
                          imageUrl: imageUrl,
                          title: title,
                          showNewBadge: isNew,
                          onTap: () => _navigateToDetails(title, imageUrl, price, description, subtitle),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: GestureDetector(
          onTap: () {
            _showInfoDialog(
              context,
              "AI Scanner",
              "AI Scanner feature is coming soon in the next update.",
            );
          },
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
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF5B8E55),
        unselectedItemColor: const Color(0xFF999999),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 28), activeIcon: Icon(Icons.home, size: 28), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined, size: 28), activeIcon: Icon(Icons.map, size: 28), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline, size: 28), activeIcon: Icon(Icons.people, size: 28), label: 'Rentals'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined, size: 28), activeIcon: Icon(Icons.shopping_bag, size: 28), label: 'Cart'),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64, height: 58,
            decoration: const BoxDecoration(color: Color(0xFF5B8E55), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 10),
          Text(label, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5B8E55), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildProductCard({required String imageUrl, required String title, required bool showNewBadge, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: const Color(0xFFF0F0F0),
                  image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                ),
              ),
              if (showNewBadge)
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF5B8E55), borderRadius: BorderRadius.circular(6)),
                    child: Text('New', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))
          ),
        ],
      ),
    );
  }

  void _showAIOptionsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('AI Features', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildAIOption(
                icon: Icons.chat_bubble_outline,
                title: 'AI Chatbot',
                description: 'Get instant gardening assistance',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
                },
              ),
              const SizedBox(height: 16),
              _buildAIOption(
                icon: Icons.camera_alt_outlined,
                title: 'Plant Disease Detector',
                description: 'Scan and identify plant diseases',
                onTap: () {
                  Navigator.pop(context);
                  _showInfoDialog(
                    context,
                    "Plant Disease Detection",
                    "Detection feature is currently disabled. It will be available in future updates.",
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildAIOption(
                icon: Icons.article_outlined,
                title: 'Blogs & Videos',
                description: 'Learn from educational content',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BlogsVideosScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIOption({required IconData icon, required String title, required String description, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: const Color(0xFF5B8E55).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: const Color(0xFF5B8E55), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(description, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF666666))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }
}
