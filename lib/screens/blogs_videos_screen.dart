import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class BlogsVideosScreen extends StatefulWidget {
  const BlogsVideosScreen({Key? key}) : super(key: key);

  @override
  State<BlogsVideosScreen> createState() => _BlogsVideosScreenState();
}

class _BlogsVideosScreenState extends State<BlogsVideosScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryGreen = const Color(0xFF5B8E55);
  final Color bgColor = const Color(0xFFF9FBFA); 
  String searchQuery = "";
  String selectedCategory = "All";
  final List<String> categories = ["All", "Indoor", "Outdoor", "Fertilizer", "Care Tips"];

  // API Keys (Make sure these are active)
  final String youtubeApiKey = "AIzaSyCwwJsTY7Fc_BIdOq8kZTOQSCtIkcoZvtw"; 
  final String newsApiKey = "47a2503254924c5383f982705057b293"; 

  List<Map<String, dynamic>>? _cachedVideos;
  String _lastFetchedVideoQuery = "";
  List<Map<String, dynamic>>? _cachedArticles;
  String _lastFetchedArticleQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Live Articles Fetching Logic ---
  Future<List<Map<String, dynamic>>> fetchLiveArticles() async {
    const String gardeningNiche = "gardening plants care";
    String baseQuery = searchQuery.isNotEmpty 
        ? "$searchQuery $gardeningNiche" 
        : (selectedCategory == "All" ? gardeningNiche : "$selectedCategory $gardeningNiche");

    if (_cachedArticles != null && _lastFetchedArticleQuery == baseQuery) {
      return _cachedArticles!;
    }

    String encodedQuery = Uri.encodeComponent(baseQuery);
    // NewsAPI 'everything' endpoint sometimes blocks localhost on free tier. 
    // Trying 'top-headlines' as a fallback or adding category.
    final String url = "https://newsapi.org/v2/everything?q=$encodedQuery&sortBy=relevancy&language=en&apiKey=$newsApiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> articles = [];
        for (var item in data['articles']) {
          if (item['urlToImage'] != null && item['title'] != null) {
            articles.add({
              'title': item['title'],
              'author': item['source']['name'] ?? 'Gardening Expert',
              'image': item['urlToImage'],
              'description': item['description'] ?? item['content'] ?? 'Click to read more.',
              'date': item['publishedAt'],
              'isVideo': false,
              'category': selectedCategory,
              'readTime': '5 min read',
            });
          }
        }
        _cachedArticles = articles;
        _lastFetchedArticleQuery = baseQuery;
        return articles;
      } else {
        // Agar NewsAPI block hai toh error message return karein
        print("NewsAPI Error: ${response.body}");
        return _getDummyArticles(); // Fallback to dummy data if API fails
      }
    } catch (e) {
      print("Article Fetch Exception: $e");
      return _getDummyArticles();
    }
  }

  // Videos fetch karne ki logic
  Future<List<Map<String, dynamic>>> fetchYouTubeVideos() async {
    const String gardeningNiche = "gardening tips"; 
    String baseQuery = searchQuery.isNotEmpty 
        ? "$searchQuery gardening" 
        : (selectedCategory == "All" ? "latest gardening 2024" : "$selectedCategory gardening tips");

    if (_cachedVideos != null && _lastFetchedVideoQuery == baseQuery) {
      return _cachedVideos!;
    }

    String encodedQuery = Uri.encodeComponent(baseQuery);
    final String url = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=$encodedQuery&type=video&maxResults=10&key=$youtubeApiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> videos = [];
        for (var item in data['items']) {
          if (item['id']['videoId'] != null) {
            videos.add({
              'title': item['snippet']['title'],
              'author': item['snippet']['channelTitle'],
              'image': item['snippet']['thumbnails']['high']['url'],
              'videoId': item['id']['videoId'],
              'description': item['snippet']['description'],
              'date': item['snippet']['publishedAt'],
              'isVideo': true,
              'category': 'YouTube',
              'readTime': 'Video',
            });
          }
        }
        _cachedVideos = videos;
        _lastFetchedVideoQuery = baseQuery;
        return videos;
      } else {
        print("YouTube API Error: ${response.body}");
        return _getDummyVideos();
      }
    } catch (e) {
      print("Video Fetch Exception: $e");
      return _getDummyVideos();
    }
  }

  // --- Fallback Dummy Data ---
  List<Map<String, dynamic>> _getDummyArticles() {
    return [
      {
        'title': 'How to Care for Indoor Plants in Summer',
        'author': 'Plantio Care',
        'image': 'https://images.unsplash.com/photo-1545239351-ef35f43d514b?q=80&w=1000&auto=format&fit=crop',
        'description': 'Keep your indoor plants hydrated and away from direct harsh sunlight during peak summer months...',
        'isVideo': false,
        'readTime': '4 min read',
      },
      {
        'title': 'Best Natural Fertilizers for Home Gardening',
        'author': 'Eco Garden',
        'image': 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?q=80&w=1000&auto=format&fit=crop',
        'description': 'Using organic compost and banana peels can boost your plant growth significantly...',
        'isVideo': false,
        'readTime': '6 min read',
      }
    ];
  }

  List<Map<String, dynamic>> _getDummyVideos() {
    return [
      {
        'title': '10 Essential Gardening Tips for Beginners',
        'author': 'Garden Master',
        'image': 'https://img.youtube.com/vi/B0xLjtZunpY/0.jpg',
        'videoId': 'B0xLjtZunpY',
        'description': 'Start your gardening journey with these simple yet effective tips...',
        'isVideo': true,
      }
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryGreen, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Learn Plants", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryGreen,
          labelColor: primaryGreen,
          unselectedLabelColor: Colors.grey.shade400,
          tabs: const [Tab(text: "Articles"), Tab(text: "Videos")],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                  _cachedVideos = null; 
                  _cachedArticles = null;
                });
              },
              decoration: InputDecoration(
                hintText: "Search gardening tips...",
                prefixIcon: Icon(Icons.search, color: primaryGreen),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
          
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                bool isSelected = selectedCategory == categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(categories[index]),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        selectedCategory = categories[index];
                        _cachedVideos = null;
                        _cachedArticles = null;
                      });
                    },
                    selectedColor: primaryGreen,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                  ),
                );
              },
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildContent(isVideoType: false),
                _buildContent(isVideoType: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent({required bool isVideoType}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: isVideoType ? fetchYouTubeVideos() : fetchLiveArticles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && 
           (isVideoType ? _cachedVideos == null : _cachedArticles == null)) {
          return Center(child: CircularProgressIndicator(color: primaryGreen));
        }
        
        // Debugging Error Message
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("Error: ${snapshot.error}\nCheck your Internet or API Key.", textAlign: TextAlign.center),
            ),
          );
        }

        var items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(child: Text("No content found for '$selectedCategory'", style: GoogleFonts.poppins()));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20), 
          itemCount: items.length, 
          itemBuilder: (c, i) => _buildModernCard(items[i])
        );
      },
    );
  }

  Widget _buildModernCard(Map<String, dynamic> data) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BlogsDetailScreen(data: data))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 25),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(24), 
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              Hero(
                tag: data['videoId'] ?? (data['image'] ?? 'img'),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), 
                  child: Image.network(
                    data['image'] ?? 'https://via.placeholder.com/200', 
                    height: 200, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(height: 200, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                  )
                ),
              ),
              if (data['isVideo'] == true) 
                const Positioned.fill(child: Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 60))),
            ]),
            Padding(
              padding: const EdgeInsets.all(20), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(data['title'] ?? 'Plant Article', maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 5),
                      Text(data['readTime'] ?? (data['isVideo'] == true ? "Video" : "5 min read"), style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
                      const Spacer(),
                      Icon(Icons.arrow_forward_ios, size: 14, color: primaryGreen),
                    ],
                  )
                ]
              )
            )
          ],
        ),
      ),
    );
  }
}

// Detail screen remains same but with safety checks
class BlogsDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const BlogsDetailScreen({Key? key, required this.data}) : super(key: key);

  @override
  State<BlogsDetailScreen> createState() => _BlogsDetailScreenState();
}

class _BlogsDetailScreenState extends State<BlogsDetailScreen> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.data['isVideo'] == true && widget.data['videoId'] != null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: widget.data['videoId'],
        autoPlay: true,
        params: const YoutubePlayerParams(showFullscreenButton: true),
      );
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300, pinned: true, elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.data['isVideo'] == true && _controller != null
                  ? YoutubePlayer(controller: _controller!, aspectRatio: 16 / 9)
                  : Image.network(widget.data['image'] ?? '', fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.grey)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.data['title'] ?? '', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Divider(height: 40),
                  Text(widget.data['description'] ?? 'Read more about this in our full guide.', style: GoogleFonts.poppins(fontSize: 15, height: 1.8)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}