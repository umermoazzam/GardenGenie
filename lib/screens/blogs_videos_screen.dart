import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BlogsVideosScreen extends StatefulWidget {
  const BlogsVideosScreen({Key? key}) : super(key: key);

  @override
  State<BlogsVideosScreen> createState() => _BlogsVideosScreenState();
}

class _BlogsVideosScreenState extends State<BlogsVideosScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryGreen = const Color(0xFF5B8E55);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Title update karne ke liye listener
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Title Logic
    String titlePrefix = _tabController.index == 0 ? "Articles on " : "Videos on ";

    final List<Map<String, dynamic>> blogItems = [
      {
        "title": "Curing Tomato Blight (AI Recommendation)",
        "author": "Plantio Expert",
        "date": "2024.03.20",
        "tag": "AI RECOMMENDED",
        "image": "https://images.unsplash.com/photo-1592419044706-39796d40f98c?w=600",
        "isVideo": false,
        "isAI": true,
        "relatedProduct": "Organic Fungicide",
        "price": "Rs. 850"
      },
      {
        "title": "David Austin, Who Breathed Life Into the Rose",
        "author": "Shyla Monic",
        "date": "2023.01.01",
        "tag": "ARTICLE",
        "image": "https://images.unsplash.com/photo-1558036117-15d82a90b9b1?w=600",
        "isVideo": false,
        "isAI": false,
        "relatedProduct": "Rose Fertilizer",
        "price": "Rs. 450"
      },
    ];

    final List<Map<String, dynamic>> videoItems = [
      {
        "title": "Even on Urban Excursions, Finding Nature",
        "author": "Shyla Monic",
        "date": "2023.01.01",
        "tag": "TUTORIAL",
        "image": "https://images.unsplash.com/photo-1523348837708-15d4a09cfac2?w=600",
        "isVideo": true,
        "isAI": false,
        "relatedProduct": "Gardening Tools Set",
        "price": "Rs. 2500"
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryGreen, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
            children: [
              TextSpan(text: titlePrefix),
              TextSpan(text: "Plants", style: TextStyle(color: primaryGreen)),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryGreen,
          labelColor: primaryGreen,
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [Tab(text: "Articles"), Tab(text: "Videos")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContentList(blogItems),
          _buildContentList(videoItems),
        ],
      ),
    );
  }

  Widget _buildContentList(List<Map<String, dynamic>> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BlogsDetailScreen(data: item)),
            );
          },
          child: _buildFigmaCard(item),
        );
      },
    );
  }

  Widget _buildFigmaCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(data['image'], height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
              if (data['isVideo'])
                const Positioned.fill(child: Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 50))),
              Positioned(
                top: 15, left: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: data['isAI'] ? Colors.orange : primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(data['tag'], style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'], style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, height: 1.3, color: Colors.black)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const CircleAvatar(radius: 12, backgroundColor: Colors.orange, child: Icon(Icons.person, size: 12, color: Colors.white)),
                    const SizedBox(width: 8),
                    Text(data['author'], style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700])),
                    const Spacer(),
                    Text(data['date'], style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BlogsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const BlogsDetailScreen({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF5B8E55);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Image.network(data['image'], height: 450, fit: BoxFit.cover),
          ),
          Positioned(
            top: 50, left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.7),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned.fill(
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.6,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                        const SizedBox(height: 25),
                        Text(data['title'], style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, height: 1.2, color: Colors.black)),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            const CircleAvatar(radius: 15, backgroundColor: Colors.orange, child: Icon(Icons.person, size: 15, color: Colors.white)),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['author'], style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text(data['date'], style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                              child: Text("+ Follow", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Text("RECOMMENDED FOR YOU", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(15)),
                          child: Row(
                            children: [
                              Container(width: 50, height: 50, decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.shopping_cart_outlined, color: primaryGreen)),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['relatedProduct'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text(data['price'], style: GoogleFonts.inter(color: primaryGreen, fontSize: 13, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, elevation: 0),
                                child: Text("BUY", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text("Description", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                        const SizedBox(height: 10),
                        Text(
                          "This tutorial is designed to help you understand plant care better. Follow these steps to ensure healthy growth. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Tortor sed tellus fusce laoreet facilisi urna imperdiet.",
                          style: GoogleFonts.inter(fontSize: 15, height: 1.6, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 100), 
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}