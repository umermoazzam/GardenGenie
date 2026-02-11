import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pod_player/pod_player.dart'; 

// --- MAIN SCREEN (BlogsVideosScreen) ---
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
    String titlePrefix = _tabController.index == 0 ? "Articles on " : "Videos on ";

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
          _buildFirestoreContent(isVideoType: false),
          _buildFirestoreContent(isVideoType: true),
        ],
      ),
    );
  }

  Widget _buildFirestoreContent({required bool isVideoType}) {
    String collectionName = isVideoType ? 'videos' : 'blogs';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collectionName).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF5B8E55)));
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(child: Text("No content available yet.", style: GoogleFonts.inter(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BlogsDetailScreen(data: data)),
                );
              },
              child: _buildFigmaCard(data),
            );
          },
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
                child: Image.network(
                  data['image'] ?? 'https://via.placeholder.com/600x400',
                  height: 200, 
                  width: double.infinity, 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              if (data['isVideo'] == true)
                const Positioned.fill(child: Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 50))),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] ?? 'No Title', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 8),
                Text(data['author'] ?? 'Admin', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- DETAIL SCREEN (BlogsDetailScreen) ---
class BlogsDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const BlogsDetailScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<BlogsDetailScreen> createState() => _BlogsDetailScreenState();
}

class _BlogsDetailScreenState extends State<BlogsDetailScreen> {
  late final PodPlayerController _podController;
  bool isVideo = false;
  bool isFollowing = false;
  bool isControllerInitialized = false; // Track initialization
  final Color primaryGreen = const Color(0xFF5B8E55);

  @override
  void initState() {
    super.initState();
    // Check if it's a video and initialize PodPlayer
    if (widget.data['isVideo'] == true && widget.data['videoUrl'] != null) {
      isVideo = true;
      _podController = PodPlayerController(
        playVideoFrom: PlayVideoFrom.youtube(widget.data['videoUrl']),
        podPlayerConfig: const PodPlayerConfig(
          autoPlay: true,
          isLooping: false,
        ),
      )..initialise().then((_) {
          if (mounted) {
            setState(() {
              isControllerInitialized = true;
            });
          }
        });
    }
  }

  @override
  void dispose() {
    if (isVideo) _podController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Header Section: PodPlayer or Image
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 450,
              color: Colors.black,
              child: isVideo
                  ? (isControllerInitialized 
                      ? PodVideoPlayer(controller: _podController)
                      : const Center(child: CircularProgressIndicator(color: Colors.white)))
                  : Image.network(
                      widget.data['image'] ?? 'https://via.placeholder.com/600x400',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 50)),
                    ),
            ),
          ),

          // Back Button
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

          // Bottom Content Sheet
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
                        Text(widget.data['title'] ?? 'No Title', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                        const SizedBox(height: 15),
                        
                        // Author & Follow Row
                        Row(
                          children: [
                            const CircleAvatar(radius: 15, backgroundColor: Colors.orange, child: Icon(Icons.person, size: 15, color: Colors.white)),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.data['author'] ?? 'Admin', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text(widget.data['date'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () => setState(() => isFollowing = !isFollowing),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowing ? Colors.grey : primaryGreen,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: Text(isFollowing ? "Following" : "+ Follow", style: const TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),
                        Text("Description", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(
                          widget.data['description'] ?? "No description available.",
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