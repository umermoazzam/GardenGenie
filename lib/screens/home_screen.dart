import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Added for Inter font
import 'search_filter_screen.dart';
import 'detection_screen.dart'; // <- Import your detection screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onNavBarTapped(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);

    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => PlantShopApp()));
    } else if (index == 2) {
      Navigator.pushNamed(context, '/rentals');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/cart');
    }
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
                // Header with Title and Profile
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
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                        child: const CircleAvatar(
                          radius: 22,
                          backgroundImage: NetworkImage(
                              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Quick Action Buttons
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PlantShopApp()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Featured Card - AI Options
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: NetworkImage(
                            'https://images.unsplash.com/photo-1606041008023-472dfb5e530f?w=800'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.6)
                          ],
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
                                Text(
                                  'New in',
                                  style: GoogleFonts.inter(
                                      color: Colors.white70, fontSize: 14),
                                ),
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
                ),
                const SizedBox(height: 24),

                // Featured Products Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildProductCard(
                        imageUrl:
                            'https://images.unsplash.com/photo-1459156212016-c812468e2115?w=400',
                        title: 'Cactus',
                        showNewBadge: true,
                        onTap: () => Navigator.pushNamed(context, '/product-detail'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProductCard(
                        imageUrl:
                            'https://images.unsplash.com/photo-1509937528035-ad76254b0356?w=400',
                        title: 'Cactus Red',
                        showNewBadge: false,
                        onTap: () => Navigator.pushNamed(context, '/product-detail'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildProductCard(
                        imageUrl:
                            'https://images.unsplash.com/photo-1614594975525-e45190c55d0b?w=400',
                        title: 'Dark Leaves',
                        showNewBadge: false,
                        onTap: () => Navigator.pushNamed(context, '/product-detail'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProductCard(
                        imageUrl:
                            'https://images.unsplash.com/photo-1614594737564-e5fc321c3f13?w=400',
                        title: 'Green Plant',
                        showNewBadge: true,
                        onTap: () => Navigator.pushNamed(context, '/product-detail'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),

      // SCAN BUTTON NAVIGATING SMOOTHLY
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              // Smooth navigation to DetectionScreen
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const OnboardingScreen(),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF5B8E55),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B8E55).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: const Icon(Icons.crop_free, color: Colors.white, size: 26),
            ),
          ),
        ),
      ),

      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          hoverColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
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
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 28),
                activeIcon: Icon(Icons.home, size: 28),
                label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined, size: 28),
                activeIcon: Icon(Icons.map, size: 28),
                label: 'Categories'),
            BottomNavigationBarItem(
                icon: Icon(Icons.people_outline, size: 28),
                activeIcon: Icon(Icons.people, size: 28),
                label: 'Rentals'),
            BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag_outlined, size: 28),
                activeIcon: Icon(Icons.shopping_bag, size: 28),
                label: 'Cart'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration:
                  const BoxDecoration(color: Color(0xFF5B8E55), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 14, color: const Color(0xFF5B8E55), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(
      {required String imageUrl,
      required String title,
      required bool showNewBadge,
      required VoidCallback onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFF0F0F0),
                    image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                  ),
                ),
                if (showNewBadge)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFF5B8E55), borderRadius: BorderRadius.circular(12)),
                      child: Text('New',
                          style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
          ],
        ),
      ),
    );
  }

  void _showAIOptionsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('AI Features',
                style: GoogleFonts.inter(
                    fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
            const SizedBox(height: 24),
            _buildAIOption(
              icon: Icons.chat_bubble_outline,
              title: 'AI Chatbot',
              description: 'Get instant gardening assistance',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/ai-chatbot');
              },
            ),
            const SizedBox(height: 16),
            _buildAIOption(
              icon: Icons.camera_alt_outlined,
              title: 'Plant Disease Detector',
              description: 'Scan and identify plant diseases',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/plant-disease-detector');
              },
            ),
            const SizedBox(height: 16),
            _buildAIOption(
              icon: Icons.article_outlined,
              title: 'Blogs & Videos',
              description: 'Learn from educational content',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/blogs');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIOption(
      {required IconData icon,
      required String title,
      required String description,
      required VoidCallback onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                    color: const Color(0xFF5B8E55).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: const Color(0xFF5B8E55), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                    const SizedBox(height: 4),
                    Text(description,
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF666666))),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFF999999)),
            ],
          ),
        ),
      ),
    );
  }
}
