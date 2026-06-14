// home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

import 'chat_screen.dart';
import 'blogs_videos_screen.dart';
import 'rental_services_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'product_details_screen.dart';
import 'detection_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _currentIndex = 0; 
  String? _profileImagePath; 

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isSearching = false;

  // Constant for Theme Consistency
  final Color primaryGreen = const Color(0xFF5B8E55);

  @override
  void initState() {
    super.initState();
    _loadProfileImage(); 

    SystemChannels.lifecycle.setMessageHandler((msg) async {
      if (msg == AppLifecycleState.resumed.toString()) {
        _loadProfileImage(); 
      }
      return null;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProfileImage(); 
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _profileImagePath = prefs.getString('profile_image_path');
      if (_profileImagePath != null && !File(_profileImagePath!).existsSync()) {
        _profileImagePath = null;
      }
    });
  }

  void _onNavBarTapped(int index) {
    if (index == _currentIndex) return;
    if (index == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categories / Shop Screen is currently disabled')),
      );
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const RentalServicesScreen()));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // Added TweenAnimationBuilder for a decent Fade + Slide entry transition
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 2500),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: child,
              ),
            );
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _isSearching 
                      ? Container(
                          key: const ValueKey('searchBar'),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                            style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: 'Search plants...',
                              hintStyle: GoogleFonts.inter(color: Colors.black.withOpacity(0.2), fontWeight: FontWeight.w500),
                              prefixIcon: Icon(Icons.search, color: primaryGreen, size: 24),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close, color: Colors.black), 
                                onPressed: () {
                                  setState(() { _isSearching = false; _searchQuery = ""; _searchController.clear(); });
                                }
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.zero, 
                                borderSide: BorderSide(color: Color(0xFFEEEEEE), width: 1)
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.zero, 
                                borderSide: BorderSide(color: Color(0xFFEEEEEE), width: 1)
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero, 
                                borderSide: BorderSide(color: primaryGreen, width: 0.5) 
                              ),
                            ),
                          ),
                        )
                      : Row(
                          key: const ValueKey('titleBar'),
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(fontSize: 25, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                                children: [
                                  const TextSpan(text: 'New on ', style: TextStyle(color: Color(0xFF1A1A1A))),
                                  TextSpan(text: 'Plantio', style: TextStyle(color: primaryGreen)),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())).then((_) => _loadProfileImage());
                              },
                              child: Container(
                                width: 43,
                                height: 43,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                  image: DecorationImage(
                                    image: (_profileImagePath != null && File(_profileImagePath!).existsSync())
                                        ? FileImage(File(_profileImagePath!)) as ImageProvider
                                        : const AssetImage('assets/icons/user.png'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                  ),

                  const SizedBox(height: 30),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickActionButton(icon: Icons.water_drop_outlined, label: 'My Garden', onTap: () => Navigator.pushNamed(context, '/my-plants')),
                        const SizedBox(width: 20),
                        _buildQuickActionButton(icon: Icons.local_florist_outlined, label: 'My Plants', onTap: () => Navigator.pushNamed(context, '/my-plants')),
                        const SizedBox(width: 20),
                        _buildQuickActionButton(icon: Icons.search, label: 'Search', onTap: () => setState(() => _isSearching = !_isSearching)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  if (!_isSearching) 
                    Container(
                      height: 200, width: double.infinity,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), image: const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1606041008023-472dfb5e530f?w=800'), fit: BoxFit.cover)),
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.6)])),
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
                                  Text('New in', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text('Create plans\nwith AI Assistant', style: GoogleFonts.inter(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold, height: 1.2)),
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
                        return Center(child: CircularProgressIndicator(color: primaryGreen));
                      }

                      final productDocs = snapshot.data!.docs.where((doc) {
                        final title = (doc['title'] ?? '').toString().toLowerCase();
                        return title.contains(_searchQuery);
                      }).toList();

                      if (productDocs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text("No products found", style: GoogleFonts.inter(color: Colors.grey, fontSize: 16)),
                              ],
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: productDocs.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.70,
                        ),
                        itemBuilder: (context, index) {
                          var data = productDocs[index].data() as Map<String, dynamic>;

                          String title = data['title'] ?? 'No Title';
                          String imageUrl = data['image'] ?? '';
                          String price = (data['price'] ?? '0').toString();
                          String description = data['description'] ?? 'No description available.';
                          String subtitle = data['subtitle'] ?? 'Garden Genie Specialist';

                          bool showBadge = false;
                          if (data['createdAt'] != null) {
                            Timestamp t = data['createdAt'] as Timestamp;
                            DateTime date = t.toDate();
                            DateTime now = DateTime.now();
                            showBadge = now.difference(date).inMinutes < 60;
                          }

                          return _buildProductCard(
                            imageUrl: imageUrl,
                            title: title,
                            showNewBadge: showBadge,
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
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantDetectionScreen())),
          child: Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
              color: primaryGreen,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: primaryGreen.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))],
            ),
            child: const Icon(Icons.crop_free, color: Colors.white, size: 26),
          ),
        ),
      ),

      bottomNavigationBar: Theme(
        data: ThemeData(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
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
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 28), activeIcon: Icon(Icons.home, size: 28), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined, size: 28), activeIcon: Icon(Icons.map, size: 28), label: 'Categories'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline, size: 28), activeIcon: Icon(Icons.people, size: 28), label: 'Rentals'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined, size: 28), activeIcon: Icon(Icons.shopping_bag, size: 28), label: 'Cart'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(width: 64, height: 58, decoration: BoxDecoration(color: primaryGreen, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 28)),
          const SizedBox(height: 10),
          Text(label, style: GoogleFonts.inter(fontSize: 14, color: primaryGreen, fontWeight: FontWeight.w500)),
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
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: const Color(0xFFF0F0F0),
                    image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                  ),
                ),
                if (showNewBadge)
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(6)),
                      child: Text('New', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
        ],
      ),
    );
  }

  void _showAIOptionsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
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
              _buildAIOption(icon: Icons.chat_bubble_outline, title: 'AI Chatbot', description: 'Get instant gardening assistance', onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
              }),
              const SizedBox(height: 16),
              _buildAIOption(icon: Icons.camera_alt_outlined, title: 'Leaf Disease Detector', description: 'Scan and identify leaf diseases', onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantDetectionScreen()));
              }),
              const SizedBox(height: 16),
              _buildAIOption(icon: Icons.article_outlined, title: 'Blogs & Videos', description: 'Learn from educational content', onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const BlogsVideosScreen()));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIOption({required IconData icon, required String title, required String description, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: primaryGreen, size: 28)),
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