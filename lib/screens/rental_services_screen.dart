// rental_services_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'cart_screen.dart'; 
import 'my_bookings_screen.dart'; 
import 'shop_screen.dart'; // Imported ShopScreen

class RentalServicesScreen extends StatefulWidget {
  const RentalServicesScreen({Key? key}) : super(key: key);

  @override
  State<RentalServicesScreen> createState() => _RentalServicesScreenState();
}

class _RentalServicesScreenState extends State<RentalServicesScreen> {
  final int _currentIndex = 2; 
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  static const Color primaryGreen = Color(0xFF5B8E55);

  final List<Map<String, dynamic>> manualGardeners = const [
    {
      'name': 'Uzair Asif',
      'skill': 'Lawn & Landscape Specialist',
      'rating': '4.8',
      'email': 'uzairasiff1227@gmail.com',
      'phone': '+923127845820',
      'image': 'assets/images/uzair.jpeg',
      'bio': 'Expert in landscape architecture and seasonal lawn maintenance with over 5 years of experience.'
    },
    {
      'name': 'Faheem Raza',
      'skill': 'Organic Kitchen Gardening',
      'rating': '4.9',
      'email': 'razafaheem001@gmail.com',
      'phone': '+923126994387',
      'image': 'assets/images/faheem.jpeg',
      'bio': 'Specialized in setting up organic vegetable patches and soil nutrient management.'
    },
    {
      'name': 'Nabeel Sheikh',
      'skill': 'Plant Healthcare & Pruning',
      'rating': '4.7',
      'email': 'nb.freelancer786@gmail.com',
      'phone': '+923236147042',
      'image': 'assets/images/nabeel.jpeg',
      'bio': 'Focuses on plant surgery, pruning, and protecting plants from common local pests.'
    },
    {
      'name': 'Wasif Ali',
      'skill': 'Terrace Garden Designer',
      'rating': '5.0',
      'email': 'showbizz951@gmail.com',
      'phone': '+923218409358',
      'image': 'assets/images/wasif.jpeg',
      'bio': 'Creative designer for small spaces, transforming terraces into lush green escapes.'
    },
    {
      'name': 'Talal Amin',
      'skill': 'Full Garden Restoration',
      'rating': '4.6',
      'email': 'talalamin39@gmail.com',
      'phone': '+923166459074',
      'image': 'assets/images/talal.jpeg',
      'bio': 'Hardworking specialist in restoring neglected gardens to their former glory.'
    },
  ];

  void _onNavBarTapped(int index) {
    if (index == _currentIndex) return;
    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (index == 1) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const ShopScreen())
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const CartScreen())
      );
    }
  }

  // --- TOOL BOOKING LOGIC WITH CALENDAR ---
  void _showToolBookingSheet(BuildContext context, String toolName, String pricePerDayStr, String toolImg) {
    int days = 1;
    DateTime? selectedStartDate;
    bool isLoading = false;
    final TextEditingController addressController = TextEditingController();
    
    int pricePerDay = int.tryParse(pricePerDayStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.zero),
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
              Text("Rent $toolName", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 5),
              Text("Rate: Rs. $pricePerDay / day", style: GoogleFonts.poppins(color: primaryGreen, fontWeight: FontWeight.w500)),
              const SizedBox(height: 25),
              
              Text("Select Start Date", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                    builder: (context, child) => Theme(
                      data: ThemeData.light().copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Colors.white, // Background of circle/header
                          onPrimary: primaryGreen, // Icons and Header text
                          surface: Colors.white,
                          onSurface: Colors.black,
                        ),
                        dialogBackgroundColor: Colors.white,
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(foregroundColor: primaryGreen),
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setSheetState(() => selectedStartDate = picked);
                },
                child: _customPickerBox(selectedStartDate == null 
                    ? "Pick Rental Date" 
                    : "${selectedStartDate!.day}/${selectedStartDate!.month}/${selectedStartDate!.year}"),
              ),
              
              const SizedBox(height: 20),
              Text("Duration (Days)", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 10),
              Row(
                children: [
                  _qtyBtn(Icons.remove, () => setSheetState(() { if(days > 1) days--; })),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text("$days Days", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  _qtyBtn(Icons.add, () => setSheetState(() => days++)),
                  const Spacer(),
                  Text("Total: Rs. ${pricePerDay * days}", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                ],
              ),
              
              const SizedBox(height: 25),
              Text("Delivery Address", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 10),
              TextField(
                controller: addressController,
                style: GoogleFonts.poppins(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Enter complete address for tool delivery",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
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
                    if (selectedStartDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a rental start date")));
                      return;
                    }
                    if (addressController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter delivery address")));
                      return;
                    }
                    setSheetState(() => isLoading = true);
                    try {
                      await _finalSubmitToolRental(toolName, days, selectedStartDate!, addressController.text, pricePerDay * days);
                      if (mounted) {
                        Navigator.pop(context);
                        _showSuccessDialog(context, "Rental request for $toolName submitted! Status will be updated by admin shortly.");
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
                    } finally {
                      if (mounted) setSheetState(() => isLoading = false);
                    }
                  },
                  child: isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("Confirm Rental", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.zero),
        child: Icon(icon, size: 20, color: Colors.black),
      ),
    );
  }

  Future<void> _finalSubmitToolRental(String tool, int days, DateTime startDate, String address, int total) async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    String finalUserId = user?.uid ?? prefs.getString('userId') ?? 'anonymous';
    String finalEmail = user?.email ?? prefs.getString('userEmail') ?? 'no-email';

    await FirebaseFirestore.instance.collection('hiring_requests').add({
      'userId': finalUserId,
      'userEmail': finalEmail,
      'userName': prefs.getString('userName') ?? 'Customer',
      'userPhone': prefs.getString('userPhone') ?? 'No Phone',
      'gardenerName': "Rental Duration: $days Days", 
      'serviceType': "Tool Rental: $tool",           
      'scheduledDateTime': startDate,                
      'address': address,
      'estimatedPrice': total,
      'status': 'Pending',                           
      'requestType': 'tool',                         
      'requestDate': FieldValue.serverTimestamp(),
    });
  }

  // --- GARDENER BOOKING LOGIC ---
  void _showBookingSheet(BuildContext context, String gardenerName) {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    bool isLoading = false;
    final TextEditingController addressController = TextEditingController();

    final Map<String, int> servicePrices = {
      'Lawn Mowing': 1499,
      'Garden Cleaning': 2000,
      'Plant Watering': 499,
      'Indoor Plant Care': 3000,
      'Plant Pruning & Trimming': 1499,
      'Pest & Disease Treatment': 2499,
      'New Plant Installation': 1000,
      'Garden Designing': 4000,
      'Weeding': 1000,
      'Tree Plantation': 3000,
      'Vegetable Garden Setup': 8000,
      'Monthly Maintenance Package': 12000,
    };

    String selectedService = servicePrices.keys.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.zero),
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
              Text("Book $gardenerName", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 20),
              Text("Select Service", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.zero, border: Border.all(color: Colors.grey[300]!)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedService,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: GoogleFonts.poppins(color: Colors.black, fontSize: 15),
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
                        Text("Date", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey[700])),
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
                                  colorScheme: const ColorScheme.light(
                                    primary: Colors.white, // Circle background #FFFFFF
                                    onPrimary: primaryGreen, // Selected day text & Header text
                                    surface: Colors.white, // Calendar surface
                                    onSurface: Colors.black, // Default text
                                  ),
                                  dialogBackgroundColor: Colors.white,
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(foregroundColor: primaryGreen),
                                  ),
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
                        Text("Time Slot", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey[700])),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 9, minute: 0),
                              builder: (context, child) => Theme(
                                data: ThemeData.light().copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: primaryGreen, // Dial Hand
                                    onPrimary: Colors.white, // Selected time text on hand
                                    surface: Colors.white, // Modal background
                                    onSurface: Colors.black, // Unselected numbers
                                    secondaryContainer: Colors.white, // Background for AM/PM box
                                  ),
                                  timePickerTheme: TimePickerThemeData(
                                    backgroundColor: Colors.white,
                                    dialBackgroundColor: Colors.grey[50]!,
                                    hourMinuteColor: WidgetStateColor.resolveWith((states) => states.contains(WidgetState.selected) ? primaryGreen : Colors.white),
                                    hourMinuteTextColor: WidgetStateColor.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.white : Colors.black),
                                  ),
                                ),
                                child: child!,
                              ),
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
              Text("Service Location", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 10),
              TextField(
                controller: addressController,
                style: GoogleFonts.poppins(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Enter your full address",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
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
                    try {
                      await _finalSubmitBooking(gardenerName, selectedService, bookingDateTime, addressController.text, servicePrices[selectedService]!);
                      if (mounted) {
                        Navigator.pop(context); 
                        _showSuccessDialog(context, "Booking request for $selectedService submitted.");
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
                    } finally {
                      if (mounted) setSheetState(() => isLoading = false);
                    }
                  },
                  child: isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("Confirm Booking", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
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
          Text(text, style: GoogleFonts.poppins(fontSize: 13, color: text.contains("Pick") ? Colors.grey : Colors.black)),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  Future<void> _finalSubmitBooking(String gardener, String service, DateTime dateTime, String address, int price) async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    String finalUserId = user?.uid ?? prefs.getString('userId') ?? 'anonymous';
    String finalEmail = user?.email ?? prefs.getString('userEmail') ?? 'no-email';

    await FirebaseFirestore.instance.collection('hiring_requests').add({
      'userId': finalUserId,
      'userEmail': finalEmail,
      'userName': prefs.getString('userName') ?? 'Customer',          
      'userPhone': prefs.getString('userPhone') ?? 'No Phone Found',  
      'gardenerName': gardener,
      'serviceType': service,
      'scheduledDateTime': dateTime,
      'address': address,
      'estimatedPrice': price,
      'status': 'Pending',
      'requestType': 'gardener',
      'requestDate': FieldValue.serverTimestamp(),
    });
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15), 
                decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), shape: BoxShape.circle), 
                child: const Icon(Icons.event_available_outlined, color: primaryGreen, size: 40) 
              ),
              const SizedBox(height: 20),
              Text('Request Sent!', 
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: const Color(0xFF666666), fontSize: 15, height: 1.4)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F5F5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('OK', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredGardeners = manualGardeners.where((g) {
      final name = g['name'].toString().toLowerCase();
      final skill = g['skill'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || skill.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Services & Rentals', 
          style: GoogleFonts.poppins(color: const Color(0xFF1A1A1A), fontSize: 18, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingsScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 25),
            // White Shaded Search Bar (Square Radius)
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.zero,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Search tools or gardeners...',
                  hintStyle: GoogleFonts.poppins(color: Colors.black.withOpacity(0.2), fontWeight: FontWeight.w500),
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
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rent Tools', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              Text('View all', style: GoogleFonts.poppins(color: primaryGreen, fontSize: 13, fontWeight: FontWeight.w600)),
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

                  if (toolDocs.isEmpty) return Center(child: Text("No tools found", style: GoogleFonts.poppins(color: Colors.grey)));

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: toolDocs.length,
                    itemBuilder: (context, index) {
                      var data = toolDocs[index].data() as Map<String, dynamic>;
                      return _buildToolCard(context, data['name'] ?? 'Tool', data['price'] ?? '0/day', data['image'] ?? '');
                    },
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 30),
          Text('Professional Gardeners', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 15),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: filteredGardeners.isEmpty 
            ? Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text("No gardeners found", style: GoogleFonts.poppins(color: Colors.grey))))
            : ListView.builder(
                key: ValueKey('garden_list_$_searchQuery'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredGardeners.length,
                itemBuilder: (context, index) => _buildGardenerRow(context, filteredGardeners[index]),
              ),
          ),
          const SizedBox(height: 100), 
        ]),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryGreen,
        unselectedItemColor: const Color(0xFF999999),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 28), activeIcon: Icon(Icons.home, size: 28), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined, size: 28), activeIcon: Icon(Icons.map, size: 28), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline, size: 28), activeIcon: Icon(Icons.people, size: 28), label: 'Rentals'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined, size: 28), activeIcon: Icon(Icons.shopping_bag, size: 28), label: 'Cart'),
        ],
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, String name, String price, String img) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 18, bottom: 10),
      // White Shaded Tool Card (Square Radius)
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.zero, 
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Image.network(img, fit: BoxFit.cover, width: double.infinity, errorBuilder: (c, e, s) => const Icon(Icons.handyman))),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                Text(price, style: GoogleFonts.poppins(color: primaryGreen, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showToolBookingSheet(context, name, price, img), 
                    style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), elevation: 0),
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

  Widget _buildGardenerRow(BuildContext context, Map<String, dynamic> g) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) => GardenerProfileScreen(
            gardener: g, 
            primaryGreen: primaryGreen, 
            onHire: () => _showBookingSheet(context, g['name'])
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        // White Shaded Gardener Row (Square Radius)
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.zero, 
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'gardener_img_${g['name']}',
              child: Container(
                width: 60, height: 60, 
                decoration: BoxDecoration(
                  shape: BoxShape.circle, border: Border.all(color: primaryGreen.withOpacity(0.1), width: 1),
                  image: DecorationImage(image: AssetImage(g['image']), fit: BoxFit.cover)
                )
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(g['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                Text(g['skill'], style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13)),
              ]),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(children: [const Icon(Icons.star, color: Colors.orange, size: 14), Text(g['rating'], style: const TextStyle(color: Colors.black))]),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _showBookingSheet(context, g['name']),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
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

class GardenerProfileScreen extends StatefulWidget {
  final Map<String, dynamic> gardener;
  final Color primaryGreen;
  final VoidCallback onHire;
  const GardenerProfileScreen({Key? key, required this.gardener, required this.primaryGreen, required this.onHire}) : super(key: key);

  @override
  State<GardenerProfileScreen> createState() => _GardenerProfileScreenState();
}

class _GardenerProfileScreenState extends State<GardenerProfileScreen> {
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: widget.primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.mark_email_read_outlined, color: widget.primaryGreen, size: 40),
              ),
              const SizedBox(height: 20),
              Text('Inquiry Sent!', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 12),
              Text('The gardener has been notified about your interest.', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF666666), height: 1.4)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F5F5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('OK', style: GoogleFonts.poppins(color: widget.primaryGreen, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendOfficialEmail(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final String cName = prefs.getString('userName') ?? "A Plantio User";
    final String cEmail = prefs.getString('userEmail') ?? "No Email Available";
    const String apiUrl = "https://umermoazzam-plantio-backend.hf.space/api/contact-inquiry";
    try {
      final response = await http.post(Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": widget.gardener['email'], "name": widget.gardener['name'], "customer_name": cName, "customer_email": cEmail}),
      );
      if (response.statusCode == 200 && context.mounted) _showSuccessDialog(context);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connection error: $e"), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text("Gardener Profile", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Hero(
              tag: 'gardener_img_${widget.gardener['name']}',
              child: Container(
                width: 140, height: 140, 
                decoration: BoxDecoration(
                  shape: BoxShape.circle, border: Border.all(color: widget.primaryGreen.withOpacity(0.1), width: 3),
                  image: DecorationImage(image: AssetImage(widget.gardener['image']), fit: BoxFit.cover)
                )
              ),
            ),
            const SizedBox(height: 20),
            Text(widget.gardener['name'], style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
            Text(widget.gardener['skill'], style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.star, color: Colors.orange, size: 20),
              const SizedBox(width: 5),
              Text(widget.gardener['rating'], style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            ]),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20), child: Divider()),
            _buildInfoSection(Icons.email_outlined, "Email Address", widget.gardener['email'], onTap: () => _sendOfficialEmail(context)),
            _buildInfoSection(Icons.phone_outlined, "Phone Number", widget.gardener['phone'], onTap: () => _makePhoneCall(widget.gardener['phone'])),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("About", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                const SizedBox(height: 10),
                Text(widget.gardener['bio'], style: GoogleFonts.poppins(color: Colors.grey[700], height: 1.5, fontSize: 15)),
              ]),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(context); widget.onHire(); },
                  style: ElevatedButton.styleFrom(backgroundColor: widget.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 18), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                  child: Text("Hire Now", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          // White Shaded Info Tile (Square Radius respect for consistent theme)
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(12), 
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: widget.primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: widget.primaryGreen, size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(value, style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 15)),
                ]),
              ),
              if (onTap != null) Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}