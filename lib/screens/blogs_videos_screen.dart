import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  final String youtubeApiKey = "AIzaSyCwwJsTY7Fc_BIdOq8kZTOQSCtIkcoZvtw"; 
  final String newsApiKey = "dc2377e2589d4e28bf1aeb46c72216c7"; 

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

  // Refined Live Articles Fetch Logic
  Future<List<Map<String, dynamic>>> fetchLiveArticles() async {
    String baseQuery = "";
    
    if (searchQuery.isNotEmpty) {
      baseQuery = "gardening $searchQuery";
    } else {
      switch (selectedCategory) {
        case "Indoor": baseQuery = "houseplants indoor gardening care"; break;
        case "Outdoor": baseQuery = "backyard gardening outdoor plants"; break;
        case "Fertilizer": baseQuery = "organic plant fertilizer gardening"; break;
        case "Care Tips": baseQuery = "gardening tips plant maintenance"; break;
        default: baseQuery = "gardening plants care"; 
      }
    }

    if (_cachedArticles != null && _lastFetchedArticleQuery == baseQuery) {
      return _cachedArticles!;
    }

    String encodedQuery = Uri.encodeComponent(baseQuery);
    final String url = "https://newsapi.org/v2/everything?q=$encodedQuery&sortBy=publishedAt&language=en&pageSize=40&apiKey=$newsApiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> articles = [];
        
        for (var item in data['articles']) {
          String title = (item['title'] ?? "").toLowerCase();
          
          // STRICT FILTERING: 
          // 1. Image null nahi honi chahiye (taake placeholder na dikhe)
          // 2. Title mein garden/plant hona zaroori hai
          if (item['urlToImage'] != null && 
              item['urlToImage'].toString().isNotEmpty &&
              (title.contains("garden") || title.contains("plant") || title.contains("horticulture"))) {
            
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
        return _getDummyArticles();
      }
    } catch (e) {
      return _getDummyArticles();
    }
  }

  Future<List<Map<String, dynamic>>> fetchYouTubeVideos() async {
    String baseQuery = searchQuery.isNotEmpty 
        ? "gardening $searchQuery" 
        : (selectedCategory == "All" ? "latest gardening tips" : "$selectedCategory gardening tips");

    if (_cachedVideos != null && _lastFetchedVideoQuery == baseQuery) {
      return _cachedVideos!;
    }

    String encodedQuery = Uri.encodeComponent(baseQuery);
    final String url = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=$encodedQuery&type=video&maxResults=10&order=date&key=$youtubeApiKey";

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
        return _getDummyVideos();
      }
    } catch (e) {
      return _getDummyVideos();
    }
  }

  List<Map<String, dynamic>> _getDummyArticles() {
    return [
      {
        'title': 'How to Care for Indoor Plants in Summer',
        'author': 'Plantio Care',
        'image': 'https://images.unsplash.com/photo-1545239351-ef35f43d514b?q=80&w=1000&auto=format&fit=crop',
        'description': 'Keep your indoor plants hydrated and away from direct harsh sunlight...',
        'isVideo': false,
        'readTime': '4 min read',
      }
    ];
  }

  List<Map<String, dynamic>> _getDummyVideos() {
    return [
      {
        'title': '10 Essential Gardening Tips for Beginners',
        'author': 'Garden Master',
        'image': 'https://images.unsplash.com/photo-1589923188900-85dae523342b?q=80&w=1000&auto=format&fit=crop',
        'videoId': 'B0xLjtZunpY',
        'description': 'Start your gardening journey...',
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
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
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
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(categories[index]),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        selectedCategory = categories[index];
                        _cachedVideos = null;
                        _cachedArticles = null;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: primaryGreen,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? primaryGreen : Colors.grey.shade200)),
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
        
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text("Error: Check Internet.", textAlign: TextAlign.center)));
        }

        var items = snapshot.data ?? [];
        if (items.isEmpty) return Center(child: Text("No relevant content found."));

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              if (isVideoType) _cachedVideos = null; else _cachedArticles = null;
            });
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(20), 
            itemCount: items.length, 
            itemBuilder: (c, i) => _buildModernCard(items[i])
          ),
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              Hero(
                tag: data['videoId'] ?? (data['title'] ?? 'img'),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), 
                  child: Image.network(
                    data['image'], 
                    height: 200, width: double.infinity, fit: BoxFit.cover,
                    // Agar browser image block kare, to ye icon dikhayega khali placeholder nahi
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200, color: Colors.grey[100], 
                      child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey))
                    ),
                  )
                ),
              ),
              if (data['isVideo'] == true) 
                Positioned.fill(child: Center(child: Icon(Icons.play_circle_fill, color: Colors.white.withOpacity(0.85), size: 70))),
            ]),
            Padding(
              padding: const EdgeInsets.all(20), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(data['title'] ?? 'Plant Article', maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 5),
                      Text(data['readTime'] ?? "5 min read", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
                      const Spacer(),
                      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.arrow_forward_ios, size: 12, color: primaryGreen)),
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
        params: const YoutubePlayerParams(showFullscreenButton: true, showControls: true),
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
            backgroundColor: Colors.white,
            leading: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.7),
              child: IconButton(icon: Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
            ),
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
                  const SizedBox(height: 10),
                  Text("By ${widget.data['author'] ?? 'Gardening Expert'}", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14)),
                  const Divider(height: 40),
                  Text(widget.data['description'] ?? 'Read more about this in our full guide.', style: GoogleFonts.poppins(fontSize: 15, height: 1.8, color: Colors.black87)),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}