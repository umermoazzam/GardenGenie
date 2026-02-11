// import 'package:flutter/material.dart';
// import 'dart:ui';
// import 'package:google_fonts/google_fonts.dart';

// class PlantDetectionScreen extends StatefulWidget {
//   const PlantDetectionScreen({Key? key}) : super(key: key);

//   @override
//   State<PlantDetectionScreen> createState() => _PlantDetectionScreenState();
// }

// class _PlantDetectionScreenState extends State<PlantDetectionScreen> with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   bool _isScanning = true;

//   @override
//   void initState() {
//     super.initState();
//     // Laser Animation Controller (Laser up and down move karega)
//     _animationController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat(reverse: true);
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // 1. Exact Background Image matching Design 12
//           Positioned.fill(
//             child: Container(
//               color: Colors.black,
//               child: Image.network(
//                 'https://images.unsplash.com/photo-1545241047-6083a3684587?w=1200', // Rubber Plant matching Design 12
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),

//           // 2. Translucent Overlay
//           Positioned.fill(
//             child: Container(color: Colors.black.withOpacity(0.1)),
//           ),

//           // 3. Back Button (Custom Circle style)
//           Positioned(
//             top: 50,
//             left: 20,
//             child: CircleAvatar(
//               backgroundColor: Colors.white.withOpacity(0.3),
//               child: IconButton(
//                 icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ),
//           ),

//           // 4. Scanning Frame & Laser Animation (Screen 12 Design)
//           Center(
//             child: Stack(
//               children: [
//                 // The Square Frame
//                 Container(
//                   width: 280,
//                   height: 280,
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
//                     borderRadius: BorderRadius.circular(24),
//                   ),
//                 ),
//                 // Moving Laser Line
//                 if (_isScanning)
//                   AnimatedBuilder(
//                     animation: _animationController,
//                     builder: (context, child) {
//                       return Positioned(
//                         top: _animationController.value * 280,
//                         left: 0,
//                         right: 0,
//                         child: Container(
//                           height: 3,
//                           decoration: BoxDecoration(
//                             boxShadow: [
//                               BoxShadow(
//                                 color: const Color(0xFF5B8E55).withOpacity(0.8),
//                                 blurRadius: 15,
//                                 spreadRadius: 2,
//                               )
//                             ],
//                             color: const Color(0xFF5B8E55),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 // Corner Borders
//                 _buildCorner(top: -2, left: -2, isTop: true, isLeft: true),
//                 _buildCorner(top: -2, right: -2, isTop: true, isLeft: false),
//                 _buildCorner(bottom: -2, left: -2, isTop: false, isLeft: true),
//                 _buildCorner(bottom: -2, right: -2, isTop: false, isLeft: false),
//               ],
//             ),
//           ),

//           // 5. Result Card (Glassmorphism Effect)
//           Positioned(
//             bottom: 40,
//             left: 20,
//             right: 20,
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(24),
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                 child: Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(24),
//                     border: Border.all(color: Colors.white.withOpacity(0.3)),
//                   ),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 60,
//                         height: 60,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(12),
//                           image: const DecorationImage(
//                             image: NetworkImage('https://images.unsplash.com/photo-1459156212016-c812468e2115?w=200'),
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               "Detected: Healthy",
//                               style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
//                             ),
//                             Text(
//                               "Plant is doing great! Keep it up.",
//                               style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
//                             ),
//                           ],
//                         ),
//                       ),
//                       CircleAvatar(
//                         backgroundColor: Colors.white.withOpacity(0.8),
//                         child: const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 16),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
          
//           // 6. Camera Controls
//           Positioned(
//             bottom: 160,
//             left: 0,
//             right: 0,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 _buildCameraButton(Icons.photo_library, () {}),
//                 const SizedBox(width: 30),
//                 _buildCameraButton(Icons.camera_alt, () {
//                   setState(() => _isScanning = !_isScanning); // Toggle scanning for demo
//                 }, isLarge: true),
//                 const SizedBox(width: 30),
//                 _buildCameraButton(Icons.flash_on, () {}),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }

//   Widget _buildCameraButton(IconData icon, VoidCallback onTap, {bool isLarge = false}) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: EdgeInsets.all(isLarge ? 20 : 12),
//         decoration: BoxDecoration(
//           color: isLarge ? const Color(0xFF5B8E55) : Colors.white.withOpacity(0.2),
//           shape: BoxShape.circle,
//           border: Border.all(color: Colors.white.withOpacity(0.5)),
//         ),
//         child: Icon(icon, color: Colors.white, size: isLarge ? 30 : 24),
//       ),
//     );
//   }

//   Widget _buildCorner({double? top, double? bottom, double? left, double? right, required bool isTop, required bool isLeft}) {
//     return Positioned(
//       top: top, bottom: bottom, left: left, right: right,
//       child: Container(
//         width: 35, height: 35,
//         decoration: BoxDecoration(
//           border: Border(
//             top: isTop && top != null ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
//             bottom: !isTop && bottom != null ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
//             left: isLeft && left != null ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
//             right: !isLeft && right != null ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
//           ),
//         ),
//       ),
//     );
//   }
// }