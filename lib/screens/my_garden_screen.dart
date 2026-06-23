import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyGardenScreen extends StatefulWidget {
  const MyGardenScreen({Key? key}) : super(key: key);

  @override
  State<MyGardenScreen> createState() => _MyGardenScreenState();
}

class _MyGardenScreenState extends State<MyGardenScreen> {
  final Color primaryGreen = const Color(0xFF5B8E55);
  final Color accentGreen = const Color(0xFFE8F5E9);
  String? _userId;

  // Real-time Weather Variables
  double currentTemp = 0.0;
  String cityName = "Faisalabad";
  String weatherMain = "Clear";
  String weatherDescription = "Fetching local climate...";
  Color climateColor = Colors.grey;
  bool isWeatherLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _fetchRealWeather();
  }

  // --- DYNAMIC WEATHER FUNCTION ---
  Future<void> _fetchRealWeather() async {
    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 3));
      } catch (e) {
        print("Location default set to Faisalabad.");
      }

      const String apiKey = "873707db4a1aea4d18feb413f23d22b0";
      String url;

      if (position != null) {
        url = 'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric';
      } else {
        url = 'https://api.openweathermap.org/data/2.5/weather?q=Faisalabad&appid=$apiKey&units=metric';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          currentTemp = data['main']['temp'].toDouble();
          cityName = data['name'];
          weatherMain = data['weather'][0]['main'];
          weatherDescription = data['weather'][0]['description'].toString().toUpperCase();
          isWeatherLoading = false;
          _updateClimateTheme();
        });
      }
    } catch (e) {
      setState(() {
        weatherDescription = "Weather unavailable";
        isWeatherLoading = false;
      });
    }
  }

  void _updateClimateTheme() {
    setState(() {
      if (weatherMain.contains("Rain") || weatherMain.contains("Drizzle")) {
        climateColor = Colors.blueAccent;
      } else if (weatherMain.contains("Cloud")) {
        climateColor = Colors.blueGrey;
      } else if (weatherMain.contains("Clear")) {
        climateColor = Colors.orangeAccent;
      } else {
        climateColor = primaryGreen;
      }
    });
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId') ?? "guest_user";
    });
  }

  // Updated function to show Dialog Box
  void _markAsWatered(String docId, String plantName) async {
    await FirebaseFirestore.instance
        .collection('user_plants')
        .doc(docId)
        .update({'lastWatered': FieldValue.serverTimestamp()});

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.opacity, color: primaryGreen),
              const SizedBox(width: 10),
              Text("Hydrated!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: primaryGreen)),
            ],
          ),
          content: Text("$plantName is hydrated!", style: GoogleFonts.poppins(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Awesome", style: GoogleFonts.poppins(color: primaryGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFA),
      body: _userId == null
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 180,
                  floating: false, pinned: true, elevation: 5, // Elevation added
                  backgroundColor: primaryGreen,
                  leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => Navigator.pop(context)
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      "My Garden",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.white),
                    ),
                    background: Stack(fit: StackFit.expand, children: [
                      Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryGreen, primaryGreen.withOpacity(0.8)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                      Positioned(right: -20, bottom: -20, child: Icon(Icons.park, size: 150, color: Colors.white.withOpacity(0.1))),
                    ]),
                  ),
                ),
                SliverToBoxAdapter(child: _buildClimateCard()),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        child: Text("Today's Care Tasks", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87))
                    )
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('user_plants')
                      .where('ownerId', isEqualTo: _userId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return SliverFillRemaining(child: _buildEmptyState());
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: 0.8
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                          String docId = snapshot.data!.docs[index].id;
                          return _buildActionCard(docId, data);
                        }, childCount: snapshot.data!.docs.length),
                      ),
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
    );
  }

  Widget _buildClimateCard() {
    return Container(
      margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ]
      ),
      child: isWeatherLoading ? const Center(child: SizedBox(height: 50, child: CircularProgressIndicator())) : Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: climateColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(weatherMain.contains("Rain") ? Icons.umbrella : Icons.wb_sunny, color: climateColor, size: 30)
        ),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("${currentTemp.toInt()}°C - $cityName", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(weatherDescription, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ])),
      ]),
    );
  }

  Widget _buildActionCard(String docId, Map<String, dynamic> data) {
    DateTime? lastWatered;
    int daysPassed = 0;
    int freq = (data['wateringFrequency'] ?? 1) as int;
    String formattedDateTime = "Never";
    String plantName = data['name'] ?? 'Plant';

    if (data['lastWatered'] != null) {
      lastWatered = (data['lastWatered'] as Timestamp).toDate();
      daysPassed = DateTime.now().difference(lastWatered).inDays;
      formattedDateTime = DateFormat('d MMM, E hh:mm a').format(lastWatered);
    }

    String statusSubtitle = "";
    Color statusColor = primaryGreen;
    String imageAlert = "";
    bool needsWater = false;

    if (daysPassed >= freq + 1) {
      statusSubtitle = "Extreme Heat: Critical!";
      statusColor = Colors.red;
      imageAlert = "EXTREME DANGER";
      needsWater = true;
    } else if (daysPassed >= freq) {
      statusSubtitle = "Thirsty: Needs Water";
      statusColor = Colors.orange;
      imageAlert = "WATER NOW";
      needsWater = true;
    } else {
      statusSubtitle = "Watered: $formattedDateTime";
      statusColor = primaryGreen;
      imageAlert = "";
      needsWater = false;
    }

    if (weatherMain.contains("Rain") && needsWater) {
      statusSubtitle = "Raining: Skip Manual";
      statusColor = Colors.blue;
      imageAlert = "NATURAL RAIN";
    }

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            )
          ]
      ),
      child: Column(children: [
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: CachedNetworkImage(
                  imageUrl: data['imageUrl'] ?? '',
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => Image.asset('assets/images/plantio.png', fit: BoxFit.cover),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              if (imageAlert.isNotEmpty)
                Positioned(
                  top: 10, left: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 5)]
                    ),
                    child: Text(
                      imageAlert,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(children: [
                Text(plantName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  statusSubtitle,
                  style: GoogleFonts.poppins(fontSize: 9, color: statusColor, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ]),
              InkWell(
                onTap: () => _markAsWatered(docId, plantName),
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                      color: needsWater ? statusColor : accentGreen,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: needsWater ? [BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : []
                  ),
                  child: Center(child: Text(needsWater ? "Water Now" : "Done", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: needsWater ? Colors.white : primaryGreen))),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.energy_savings_leaf_outlined, size: 100, color: primaryGreen.withOpacity(0.1)),
      const SizedBox(height: 16),
      Text("Your garden is empty", style: GoogleFonts.poppins(color: Colors.black54, fontSize: 18, fontWeight: FontWeight.w600)),
      Text("No plants found in your collection.", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14)),
    ]);
  }
}