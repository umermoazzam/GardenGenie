import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_screen.dart'; 

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Activity History', 
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18), // Updated to Poppins
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('history')
            .where('userId', isEqualTo: currentUserId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF5B8E55)));
          }
          
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("No history yet", style: GoogleFonts.poppins(color: Colors.grey)), // Updated to Poppins
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String type = data['type'] ?? "";
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    if (type == 'chat') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => IndividualChatScreen(userId: currentUserId)),
                      );
                    } else if (type == 'scan') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LeafScanDetailScreen(data: data)),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                            image: (data['imageUrl'] != null && data['imageUrl'] != "")
                                ? DecorationImage(image: NetworkImage(data['imageUrl']), fit: BoxFit.cover)
                                : null,
                          ),
                          child: (data['imageUrl'] == null || data['imageUrl'] == "")
                              ? const Icon(
                                  Icons.eco_outlined, 
                                  color: Color(0xFF5B8E55),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'] ?? "Activity", 
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16), // Updated to Poppins
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Result: ${data['result'] ?? 'Completed'}", 
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600), // Updated to Poppins
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class LeafScanDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const LeafScanDetailScreen({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF5B8E55);
    String scanDate = "Recently";
    
    if (data['timestamp'] != null) {
      DateTime dt = (data['timestamp'] as Timestamp).toDate();
      scanDate = "${dt.day}/${dt.month}/${dt.year}";
    }

    final String? imageUrl = data['imageUrl'];
    final bool hasValidImage = imageUrl != null && imageUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Diagnosis Result', 
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18), // Updated to Poppins
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            
            Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.12),
                      blurRadius: 32,
                      spreadRadius: 6,
                      offset: const Offset(0, 8),
                    )
                  ],
                  border: Border.all(color: Colors.white, width: 4),
                  image: hasValidImage
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !hasValidImage
                    ? const Center(
                        child: Icon(
                          Icons.eco, 
                          size: 80, 
                          color: primaryColor,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 36),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEFEFEF)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.015), 
                    blurRadius: 12, 
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Summary", 
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black), // Updated to Poppins
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F1F1)),
                  const SizedBox(height: 20),
                  
                  _infoTile("Title", data['title'] ?? "Analysis"),
                  _infoTile("Status", data['result'] ?? "Unknown", isResult: true),
                  _infoTile("Analyzed on", scanDate),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor.withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: primaryColor, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        "Expert Tip", 
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: primaryColor), // Updated to Poppins
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Keep monitoring your plants regularly. You can always ask Garden Genie for further advice based on this diagnosis.",
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87, height: 1.5), // Updated to Poppins
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value, {bool isResult = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(), 
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.2), // Updated to Poppins
          ),
          const SizedBox(height: 6),
          Text(
            value, 
            style: GoogleFonts.poppins(
              fontSize: 16, 
              fontWeight: FontWeight.w600, 
              color: isResult ? const Color(0xFF5B8E55) : Colors.black87,
            ), // Updated to Poppins
          ),
        ],
      ),
    );
  }
}