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
import 'shop_screen.dart'; 

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
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => const ShopScreen())
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
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1500),
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
                            style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: 'Search plants...',
                              hintStyle: GoogleFonts.poppins(color: Colors.black.withOpacity(0.2), fontWeight: FontWeight.w500),
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
                              border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
                              enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: primaryGreen, width: 0.5)),
                            ),
                          ),
                        )
                      : Container(
                          key: const ValueKey('titleBar'),
                          width: double.infinity,
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 55.0, right: 60.0), 
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w600, letterSpacing: -0.5),
                                    children: [
                                      const TextSpan(text: 'New on ', style: TextStyle(color: Color(0xFF1A1A1A))),
                                      TextSpan(text: 'Plantio', style: TextStyle(color: primaryGreen)),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())).then((_) => _loadProfileImage());
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(2), 
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: (_profileImagePath != null && File(_profileImagePath!).existsSync())
                                              ? FileImage(File(_profileImagePath!)) as ImageProvider
                                              : const AssetImage('assets/icons/user.png'),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16), 
                        image: const DecorationImage(
                          image: AssetImage('assets/images/banner.png'), 
                          fit: BoxFit.cover
                        )
                      ),
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
                                  Text('New in', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text('Create plans\nwith AI Assistant', style: GoogleFonts.poppins(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w600, height: 1.2)),
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
                      if (snapshot.hasError) return Text('Something went wrong', style: GoogleFonts.poppins());
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
                                Text("No products found", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)),
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
                            showBadge = DateTime.now().difference(t.toDate()).inMinutes < 60;
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
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantDetectionScreen())),
          child: Container(
            width: 65, height: 65,
            decoration: BoxDecoration(
              color: primaryGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.crop_free, 
              color: Colors.white, 
              size: 30, 
            ),
          ),
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, -4)),
            BoxShadow(color: const Color(0xFF000000).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -6)),
          ],
        ),
        child: Theme(
          data: ThemeData(splashColor: Colors.transparent, highlightColor: Colors.transparent),
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
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(-2, -2)),
                BoxShadow(color: const Color(0xFF000000).withOpacity(0.12), blurRadius: 12, offset: const Offset(4, 5)),
              ],
            ), 
            child: Icon(icon, color: primaryGreen, size: 28),
          ),
          const SizedBox(height: 10),
          Text(label, style: GoogleFonts.poppins(fontSize: 14, color: primaryGreen, fontWeight: FontWeight.w500)),
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
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
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
                        child: Text('New', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
        ],
      ),
    );
  }

  void _showAIOptionsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('AI Features', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 24),
              _buildAIOption(icon: Icons.chat_bubble_outline_rounded, title: 'AI Chatbot', description: 'Get instant gardening assistance', onTap: () async { 
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                final String? uid = prefs.getString('userId'); 
                Navigator.push(context, MaterialPageRoute(builder: (_) => IndividualChatScreen(userId: uid ?? "guest_user")));
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
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ AI Option Widget with White Shaded Effect
  Widget _buildAIOption({required IconData icon, required String title, required String description, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap, 
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50, 
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.08), 
                    borderRadius: BorderRadius.circular(12)
                  ), 
                  child: Icon(icon, color: primaryGreen, size: 26)
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                      const SizedBox(height: 2),
                      Text(description, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF888888), fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFBBBBBB)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}