// rental_services_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RentalServicesScreen extends StatefulWidget {
  const RentalServicesScreen({Key? key}) : super(key: key);

  @override
  State<RentalServicesScreen> createState() => _RentalServicesScreenState();
}

class _RentalServicesScreenState extends State<RentalServicesScreen> {
  // --- SEARCH LOGIC ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // --- MANUAL GARDENERS DATA ---
  final List<Map<String, dynamic>> manualGardeners = const [
    {
      'name': 'Muhammad Beelal',
      'skill': 'Lawn & Landscape Specialist',
      'rating': '4.8',
      'email': 'beelalchaudhary@gmail.com',
      'phone': '+923424882223',
      'image': 'https://img.freepik.com/free-photo/portrait-man-smiling-outdoors_23-2148946213.jpg',
      'bio': 'Expert in landscape architecture and seasonal lawn maintenance with over 5 years of experience.'
    },
    {
      'name': 'Wasif Ali',
      'skill': 'Organic Kitchen Gardening',
      'rating': '4.9',
      'email': 'showbizz951@gmail.com',
      'phone': '+923218409358',
      'image': 'https://img.freepik.com/free-photo/medium-shot-woman-working-nature_23-2149021516.jpg',
      'bio': 'Specialized in setting up organic vegetable patches and soil nutrient management.'
    },
    {
      'name': 'Muhammad Haseeb Shahid',
      'skill': 'Plant Healthcare & Pruning',
      'rating': '4.7',
      'email': 'm.haseebntu@gmail.com',
      'phone': '+923166415699',
      'image': 'https://img.freepik.com/free-photo/confident-gardener-standing-with-arms-crossed_23-2148113110.jpg',
      'bio': 'Focuses on plant surgery, pruning, and protecting plants from common local pests.'
    },
    {
      'name': 'Umer Moazzam',
      'skill': 'Terrace Garden Designer',
      'rating': '5.0',
      'email': 'umermoazzam2@gmail.com',
      'phone': '+923326582650',
      'image': 'https://img.freepik.com/free-photo/female-florist-working-nursery_23-2148894172.jpg',
      'bio': 'Creative designer for small spaces, transforming terraces into lush green escapes.'
    },
    {
      'name': 'Muhammad Junaid',
      'skill': 'Full Garden Restoration',
      'rating': '4.6',
      'email': 'junaid.gardeners@gmail.com',
      'phone': '+92 333 5556677',
      'image': 'https://img.freepik.com/free-photo/man-working-garden-nursery_23-2148894145.jpg',
      'bio': 'Hardworking specialist in restoring neglected gardens to their former glory.'
    },
  ];

  // --- BOOKING SHEET LOGIC ---
  void _showBookingSheet(BuildContext context, String gardenerName) {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    bool isLoading = false;
    final TextEditingController addressController = TextEditingController();
    const primaryGreen = Color(0xFF5B8E55);

    final Map<String, int> servicePrices = {
      'Lawn Mowing': 500,
      'Planting': 300,
      'Garden Cleanup': 800,
      'Full Maintenance': 1200,
    };

    String selectedService = servicePrices.keys.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero,
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20, left: 25, right: 25,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 50, height: 5, decoration: const BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.zero))),
              const SizedBox(height: 20),
              Text("Book $gardenerName", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 20),
              Text("Select Service", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.zero, border: Border.all(color: Colors.grey[300]!)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedService,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: GoogleFonts.inter(color: Colors.black, fontSize: 15),
                    items: servicePrices.keys.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setSheetState(() => selectedService = val!),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Date", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey[700])),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                              builder: (context, child) => Theme(
                                data: ThemeData.light().copyWith(
                                  colorScheme: const ColorScheme.light(primary: primaryGreen, onPrimary: Colors.white, surface: Colors.white, onSurface: Colors.black),
                                  dialogBackgroundColor: Colors.white,
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) setSheetState(() => selectedDate = picked);
                          },
                          child: _customPickerBox(selectedDate == null ? "Pick Date" : "${selectedDate!.day}/${selectedDate!.month}"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Time Slot", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey[700])),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 9, minute: 0),
                            );
                            if (picked != null) setSheetState(() => selectedTime = picked);
                          },
                          child: _customPickerBox(selectedTime == null ? "Pick Time" : selectedTime!.format(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text("Service Location", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 10),
              TextField(
                controller: addressController,
                style: GoogleFonts.inter(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Enter your full address",
                  hintStyle: GoogleFonts.inter(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                  enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: primaryGreen)),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    elevation: 0,
                  ),
                  onPressed: isLoading ? null : () async {
                    if (selectedDate == null || selectedTime == null || addressController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all details")));
                      return;
                    }
                    setSheetState(() => isLoading = true);
                    final bookingDateTime = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, selectedTime!.hour, selectedTime!.minute);
                    await _finalSubmitBooking(context, gardenerName, selectedService, bookingDateTime, addressController.text, servicePrices[selectedService]!);
                    setSheetState(() => isLoading = false);
                    Navigator.pop(context);
                  },
                  child: isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("Confirm Booking", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customPickerBox(String text) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.zero, border: Border.all(color: Colors.grey[300]!)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: GoogleFonts.inter(fontSize: 13, color: text.contains("Pick") ? Colors.grey : Colors.black)),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  Future<void> _finalSubmitBooking(BuildContext context, String gardener, String service, DateTime dateTime, String address, int price) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('hiring_requests').add({
        'userId': user?.uid ?? 'anonymous',
        'userEmail': user?.email ?? 'no-email',
        'gardenerName': gardener,
        'serviceType': service,
        'scheduledDateTime': dateTime,
        'address': address,
        'estimatedPrice': price,
        'status': 'Pending',
        'requestDate': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        _showSuccessDialog(context, "Request sent for $service on ${dateTime.day}/${dateTime.month}.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(15), decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.rectangle), child: const Icon(Icons.check_circle, color: Color(0xFF5B8E55), size: 50)),
            const SizedBox(height: 20),
            Text('Request Sent!', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B8E55), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), padding: const EdgeInsets.symmetric(vertical: 12)),
                child: Text('Great!', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF5B8E55);

    final filteredGardeners = manualGardeners.where((g) {
      final name = g['name'].toString().toLowerCase();
      final skill = g['skill'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || skill.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white, // MATCHING PROFILE SCREEN
        elevation: 0,
        scrolledUnderElevation: 0, // MATCHING PROFILE SCREEN
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20), // MATCHING PROFILE SCREEN
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Services & Rentals', 
          style: GoogleFonts.inter(color: const Color(0xFF1A1A1A), fontSize: 18, fontWeight: FontWeight.w600) // MATCHING PROFILE SCREEN STYLE
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 25),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Search tools or gardeners...',
                hintStyle: GoogleFonts.inter(color: Colors.black.withOpacity(0.2), fontWeight: FontWeight.w500),
                prefixIcon: const Icon(Icons.search, color: primaryGreen, size: 24),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
                enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
                focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: primaryGreen, width: 2.5)),
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rent Tools', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              Text('View all', style: GoogleFonts.inter(color: primaryGreen, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 15),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: SizedBox(
              key: ValueKey(_searchQuery),
              height: 350, 
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('rentals').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryGreen));
                  
                  final toolDocs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (toolDocs.isEmpty) {
                    return Center(child: Text("No tools found", style: GoogleFonts.inter(color: Colors.grey)));
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: toolDocs.length,
                    itemBuilder: (context, index) {
                      var data = toolDocs[index].data() as Map<String, dynamic>;
                      return _buildToolCard(context, data['name'] ?? 'Tool', data['price'] ?? '0/day', data['image'] ?? '', primaryGreen);
                    },
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 30),
          Text('Professional Gardeners', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 15),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: filteredGardeners.isEmpty 
            ? Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text("No gardeners found", style: GoogleFonts.inter(color: Colors.grey)),
            ))
            : ListView.builder(
              key: ValueKey('garden_list_$_searchQuery'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredGardeners.length,
              itemBuilder: (context, index) {
                final g = filteredGardeners[index];
                return _buildGardenerRow(context, g, primaryGreen);
              },
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, String name, String price, String img, Color color) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 18, bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.zero, border: Border.all(color: Colors.grey[100]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Image.network(img, fit: BoxFit.cover, width: double.infinity, errorBuilder: (c, e, s) => const Icon(Icons.handyman))),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                Text(price, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {}, 
                    style: ElevatedButton.styleFrom(backgroundColor: color, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), elevation: 0),
                    child: const Text("Rent Now", style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGardenerRow(BuildContext context, Map<String, dynamic> g, Color color) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) => GardenerProfileScreen(
            gardener: g, 
            primaryGreen: color, 
            onHire: () => _showBookingSheet(context, g['name'])
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'gardener_img_${g['name']}',
              child: Container(width: 60, height: 60, decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(g['image']), fit: BoxFit.cover))),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(g['name'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                Text(g['skill'], style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13)),
              ]),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(children: [const Icon(Icons.star, color: Colors.orange, size: 14), Text(g['rating'], style: const TextStyle(color: Colors.black))]),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _showBookingSheet(context, g['name']),
                  style: ElevatedButton.styleFrom(backgroundColor: color, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                  child: const Text('Hire', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GardenerProfileScreen extends StatelessWidget {
  final Map<String, dynamic> gardener;
  final Color primaryGreen;
  final VoidCallback onHire;

  const GardenerProfileScreen({Key? key, required this.gardener, required this.primaryGreen, required this.onHire}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Gardener Profile", style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Hero(
              tag: 'gardener_img_${gardener['name']}',
              child: Container(width: 140, height: 140, decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(gardener['image']), fit: BoxFit.cover))),
            ),
            const SizedBox(height: 20),
            Text(gardener['name'], style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
            Text(gardener['skill'], style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.star, color: Colors.orange, size: 20),
              const SizedBox(width: 5),
              Text(gardener['rating'], style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            ]),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20), child: Divider()),
            _buildInfoSection(Icons.email, "Email", gardener['email']),
            _buildInfoSection(Icons.phone, "Phone", gardener['phone']),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("About", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                  const SizedBox(height: 10),
                  Text(gardener['bio'], style: GoogleFonts.inter(color: Colors.grey[700], height: 1.5, fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onHire();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, padding: const EdgeInsets.symmetric(vertical: 18), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                  child: Text("Hire Now", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.zero),
            child: Icon(icon, color: primaryGreen, size: 20),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
              Text(value, style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}