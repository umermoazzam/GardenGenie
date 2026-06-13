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
        title: Text('Activity History', 
          style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
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
                  Text("No history yet", style: GoogleFonts.inter(color: Colors.grey)),
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
                      // ✅ UPDATED: Navigates to Detail Screen instead of Detection Screen
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
                              ? Icon(
                                  type == 'chat' ? Icons.chat_bubble_outline : Icons.eco_outlined, 
                                  color: const Color(0xFF5B8E55)
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['title'] ?? "Activity", 
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text("Result: ${data['result'] ?? 'Completed'}", 
                                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
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

// ✅ NEW: Scan Detail Screen so users can see previous diagnosis without opening camera
class LeafScanDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const LeafScanDetailScreen({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Leaf Analysis Result', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Icon(Icons.eco, size: 100, color: Color(0xFF5B8E55))),
            const SizedBox(height: 30),
            Text("Leaf Diagnosis Summary", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _detailRow("Title:", data['title'] ?? "N/A"),
            _detailRow("Result:", data['result'] ?? "Healthy"),
            _detailRow("Scanned on:", data['timestamp']?.toDate().toString().split(' ')[0] ?? "Recently"),
            const SizedBox(height: 40),
            Text("Tip:", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              "Keep monitoring your plants regularly. You can always ask Garden Genie for further advice based on this diagnosis.",
              style: GoogleFonts.inter(fontSize: 15, color: Colors.grey.shade700, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16)),
          const SizedBox(width: 10),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
        ],
      ),
    );
  }
}