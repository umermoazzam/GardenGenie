// gardener_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting

class GardenerDashboard extends StatelessWidget {
  const GardenerDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF5B8E55);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Soft background for premium feel
      appBar: AppBar(
        title: Text(
          "Gardener Dashboard", 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context), 
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent)
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('hiring_requests')
            .orderBy('requestDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryGreen));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No Requests Yet", 
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)
              )
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              
              // Formatting Date and Time from Firestore Timestamp
              String formattedBookingDateTime = "No Date Scheduled";
              if (data['scheduledDateTime'] != null) {
                DateTime dt = (data['scheduledDateTime'] as Timestamp).toDate();
                formattedBookingDateTime = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
              }
              
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey[200]!, width: 1.5),
                  borderRadius: BorderRadius.circular(12), // Matching structural rounding
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data['serviceType'] ?? 'Garden Service', 
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1A1A1A))
                          ),
                          _statusBadge(data['status']),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 18, color: primaryGreen),
                          const SizedBox(width: 8),
                          Text(
                            "Customer: ${data['userName']}", 
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF555555))
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // NEW: Date and Time Row added for Gardener
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 18, color: primaryGreen),
                          const SizedBox(width: 8),
                          Text(
                            formattedBookingDateTime, 
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400, color: const Color(0xFF555555))
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18, color: primaryGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Address: ${data['address']}", 
                              style: GoogleFonts.poppins(color: const Color(0xFF777777), fontSize: 13, fontWeight: FontWeight.w400)
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30, thickness: 1),
                      
                      // Status Action Buttons with Plantio Green Concept
                      if (data['status'] == 'Pending')
                        Row(
                          children: [
                            Expanded(
                              child: _actionButton(
                                "Confirm", 
                                primaryGreen, 
                                () => _updateStatus(doc.id, "Confirmed"),
                                isOutlined: false
                              )
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _actionButton(
                                "Reject", 
                                Colors.redAccent, 
                                () => _updateStatus(doc.id, "Cancelled"),
                                isOutlined: true
                              )
                            ),
                          ],
                        )
                      else if (data['status'] == 'Confirmed')
                        SizedBox(
                          width: double.infinity, 
                          child: _actionButton(
                            "Mark Completed", 
                            primaryGreen, 
                            () => _updateStatus(doc.id, "Completed"),
                            isOutlined: false
                          )
                        )
                      else
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text(
                              "Booking Closed", 
                              style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _actionButton(String title, Color color, VoidCallback onPressed, {required bool isOutlined}) {
    return SizedBox(
      height: 46,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color, width: 1.5),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: Text(
                title, 
                style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 14)
              ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color, 
                elevation: 0,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)
              ),
              child: Text(
                title, 
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
              ),
            ),
    );
  }

  void _updateStatus(String id, String status) {
    FirebaseFirestore.instance.collection('hiring_requests').doc(id).update({'status': status});
  }

  Widget _statusBadge(String status) {
    Color baseColor;
    if (status == 'Confirmed') {
      baseColor = const Color(0xFF2196F3); // Blue for confirmed
    } else if (status == 'Completed') {
      baseColor = const Color(0xFF4CAF50); // Clean Green for done
    } else if (status == 'Cancelled') {
      baseColor = Colors.redAccent;
    } else {
      baseColor = const Color(0xFFFF9800); // Orange for pending
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.12), 
        borderRadius: BorderRadius.circular(30), // Pill-shaped badges look cleaner
      ),
      child: Text(
        status, 
        style: GoogleFonts.poppins(color: baseColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)
      ),
    );
  }
}