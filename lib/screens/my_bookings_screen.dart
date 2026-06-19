import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  String? _finalId;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadUserContext();
  }

  // Yeh function wahi ID nikalega jo RentalServiceScreen use kar rahi hai
  Future<void> _loadUserContext() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    
    setState(() {
      // Priority: 1. SharedPreferences (MongoDB ID) 2. Firebase Auth UID
      _finalId = prefs.getString('userId') ?? user?.uid;
      _initialized = true;
    });
    debugPrint("MyBookings querying for ID: $_finalId");
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF5B8E55);

    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: primaryGreen)));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("My Bookings", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Sirf wahi data dikhayega jo is specific ID se match karega
        stream: FirebaseFirestore.instance
            .collection('hiring_requests')
            .where('userId', isEqualTo: _finalId) 
            .orderBy('requestDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Agar yahan error aye toh Browser Console mein check karein, Index link hoga
            debugPrint("Firestore Error: ${snapshot.error}");
            return Center(child: Text("Syncing with server...", style: GoogleFonts.poppins(color: Colors.grey)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryGreen));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("No bookings yet", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var booking = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              
              Color statusColor = _getStatusColor(booking['status'] ?? 'Pending', primaryGreen);
              DateTime scheduledDate = (booking['scheduledDateTime'] as Timestamp).toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(booking['serviceType'] ?? 'Gardening', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                        _statusBadge(booking['status'] ?? 'Pending', statusColor),
                      ],
                    ),
                    const Divider(height: 25),
                    _infoRow(Icons.person_outline, "Gardener: ${booking['gardenerName']}"),
                    const SizedBox(height: 8),
                    _infoRow(Icons.access_time, DateFormat('dd MMM yyyy, hh:mm a').format(scheduledDate)),
                    const SizedBox(height: 8),
                    _infoRow(Icons.location_on_outlined, booking['address'] ?? 'Address'),
                    const Divider(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Estimated Price", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
                        Text("Rs. ${booking['estimatedPrice']}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status, Color primary) {
    if (status == 'Confirmed') return Colors.blue;
    if (status == 'Completed') return primary;
    if (status == 'Cancelled') return Colors.red;
    return Colors.orange;
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: GoogleFonts.poppins(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 18, color: Colors.grey),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]);
  }
}