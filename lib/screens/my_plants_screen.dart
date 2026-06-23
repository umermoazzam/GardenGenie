import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; 
import 'add_plants_screen.dart';

class MyPlantsScreen extends StatefulWidget {
  const MyPlantsScreen({Key? key}) : super(key: key);

  @override
  State<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends State<MyPlantsScreen> {
  final Color primaryGreen = const Color(0xFF5B8E55);
  String? userId;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => userId = prefs.getString('userId') ?? "guest_user");
  }

  // Updated: Dialog background is now pure white
  void _waterPlantAction(String docId) {
    FirebaseFirestore.instance.collection('user_plants').doc(docId).update({
      'lastWatered': FieldValue.serverTimestamp(),
    }).then((_) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white, // Set to pure white
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: primaryGreen, size: 50),
                const SizedBox(height: 15),
                Text("Plant Watered!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
        );
        // Auto-close dialog after 1.5 seconds
        Future.delayed(const Duration(seconds: 1, milliseconds: 500), () {
          if (Navigator.canPop(context)) Navigator.pop(context);
        });
      }
    });
  }

  void _showPlantDetails(Map<String, dynamic> plant, String docId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 15), height: 5, width: 50, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25), 
                      child: Image.network(plant['imageUrl'] ?? '', height: 280, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(height: 200, color: Colors.grey[100], child: const Icon(Icons.broken_image, size: 80, color: Colors.grey)))
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(plant['name']?.toString() ?? 'Unnamed', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black)),
                  Text(plant['species']?.toString() ?? 'Unknown Species', style: GoogleFonts.poppins(color: primaryGreen, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 25),
                  _detailRow(Icons.location_on_rounded, "Location", plant['location']?.toString() ?? 'N/A'),
                  _detailRow(Icons.water_drop_rounded, "Watering Frequency", "Every ${plant['wateringFrequency'] ?? 1} days"),
                  const SizedBox(height: 35),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: primaryGreen.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        _waterPlantAction(docId);
                        Navigator.pop(context); 
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 0),
                      child: Text("WATER NOW", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF8FAF8), borderRadius: BorderRadius.circular(15)),
      child: Row(children: [
        Icon(icon, color: primaryGreen, size: 22), 
        const SizedBox(width: 15), 
        Text("$label: ", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)), 
        Text(value, style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87))
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: Text('My Collection', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]
              ),
              child: TextField(
                onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: "Search your plants...", 
                  hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: primaryGreen), 
                  filled: true, 
                  fillColor: Colors.white, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15)
                ),
              ),
            ),
          ),
        ),
      ),
      body: userId == null ? Center(child: CircularProgressIndicator(color: primaryGreen)) : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('user_plants').where('ownerId', isEqualTo: userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: primaryGreen));
          
          var docs = snapshot.data!.docs.where((d) {
            var data = d.data() as Map<String, dynamic>;
            String name = (data['name'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery);
          }).toList();

          if (docs.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var plant = docs[index].data() as Map<String, dynamic>;
              String docId = docs[index].id;
              return _buildPlantCard(plant, docId);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPlantScreen())), 
        backgroundColor: primaryGreen, 
        elevation: 8,
        icon: const Icon(Icons.add_rounded, color: Colors.white), 
        label: Text("Add Plant", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold))
      ),
    );
  }

  Widget _buildPlantCard(Map<String, dynamic> plant, String docId) {
    bool isOverdue = false;
    String lastWateredText = "Never";

    if (plant['lastWatered'] != null) {
      DateTime last = (plant['lastWatered'] as Timestamp).toDate();
      lastWateredText = DateFormat('dd MMM, hh:mm a').format(last);
      int freq = (plant['wateringFrequency'] ?? 1) as int;
      if (DateTime.now().difference(last).inDays >= freq) isOverdue = true;
    }

    return GestureDetector(
      onTap: () => _showPlantDetails(plant, docId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(22), 
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))
          ],
          border: Border.all(color: isOverdue ? Colors.red.withOpacity(0.2) : Colors.white, width: 2),
        ),
        child: IntrinsicHeight(
          child: Row(children: [
            Container(
              width: 100, height: 110, 
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)), 
                image: plant['imageUrl'] != null && plant['imageUrl'] != '' 
                  ? DecorationImage(image: NetworkImage(plant['imageUrl']), fit: BoxFit.cover) 
                  : null
              ), 
              child: plant['imageUrl'] == null || plant['imageUrl'] == '' ? const Icon(Icons.eco_rounded, color: Colors.grey, size: 40) : null
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15), 
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(plant['name']?.toString() ?? 'Unnamed', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(plant['species']?.toString() ?? 'Unknown', style: GoogleFonts.poppins(color: primaryGreen, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text("Last: $lastWateredText", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      GestureDetector(
                        onTap: () => _waterPlantAction(docId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isOverdue ? Colors.red.withOpacity(0.1) : primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "WATER", 
                            style: GoogleFonts.poppins(color: isOverdue ? Colors.red : primaryGreen, fontSize: 10, fontWeight: FontWeight.w800)
                          ),
                        ),
                      ),
                    ],
                  ),
                ])
              )
            ),
            PopupMenuButton<String>(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (v) {
                if (v == 'delete') _showDeleteDialog(docId);
                if (v == 'edit') Navigator.push(context, MaterialPageRoute(builder: (context) => AddPlantScreen(docId: docId, plantData: plant)));
              },
              itemBuilder: (c) => [
                PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_rounded, size: 18), const SizedBox(width: 10), Text("Edit", style: GoogleFonts.poppins(fontSize: 14))])),
                PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_rounded, color: Colors.red, size: 18), const SizedBox(width: 10), Text("Delete", style: GoogleFonts.poppins(fontSize: 14, color: Colors.red))])),
              ],
            )
          ]),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(String docId) async {
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      actionsAlignment: MainAxisAlignment.center,
      title: Text("", style: GoogleFonts.poppins(fontWeight: FontWeight.w800)), 
      content: Text("Remove this plant from your collection?", style: GoogleFonts.poppins(fontSize: 14)), 
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600))),
        TextButton(onPressed: () { FirebaseFirestore.instance.collection('user_plants').doc(docId).delete(); Navigator.pop(c); }, child: Text("Delete", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)))
      ]
    ));
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.filter_vintage_outlined, size: 80, color: Colors.grey[300]),
        const SizedBox(height: 15),
        Text("No plants found", style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600)),
      ],
    )
  );
}