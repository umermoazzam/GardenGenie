// chat_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

void main() {
  runApp(const PlantChatApp());
}

class PlantChatApp extends StatelessWidget {
  const PlantChatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const ChatListScreen(),
    );
  }
}

// Screen 1: Individual Chat Screen (Plantio AI)
class IndividualChatScreen extends StatefulWidget {
  const IndividualChatScreen({Key? key}) : super(key: key);

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final Color darkTextColor = const Color(0xFF1B1E28);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.withOpacity(0.1),
            height: 1.0,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: darkTextColor, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF5B8C51),
              child: Icon(Icons.psychology, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plantio AI',
                  style: GoogleFonts.inter(
                    color: darkTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Always active',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF5B8C51),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.more_vert, color: darkTextColor, size: 18),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 32, bottom: 16),
              children: [
                Center(
                  child: Text(
                    'Today',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF9E9E9E),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildReceivedMessage(
                  'Hello! I am Plantio AI. How can I help you with your garden today?',
                  '8:37',
                ),
                _buildSentMessage('My Monstera leaves are turning yellow.', '9:24'),
                _buildReceivedMessage(
                  'Yellow leaves can be caused by overwatering or lack of light. Are the stems feeling soft or firm?',
                  '9:25',
                ),
              ],
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildReceivedMessage(String message, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF5B8C51),
            child: Icon(Icons.psychology, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message, style: GoogleFonts.inter(fontSize: 14, color: darkTextColor)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(time, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9E9E9E))),
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all, size: 14, color: Color(0xFF5B8C51)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentMessage(String message, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFFEA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(message, style: GoogleFonts.inter(fontSize: 14, color: darkTextColor)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(time, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5B8C51))),
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all, size: 14, color: Color(0xFF5B8C51)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 35, left: 16, right: 16, top: 8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5), 
                  borderRadius: BorderRadius.circular(30)
                ),
                child: TextField(
                  style: GoogleFonts.inter(color: darkTextColor),
                  decoration: InputDecoration(
                    hintText: 'Type you message',
                    border: InputBorder.none,
                    hintStyle: GoogleFonts.inter(color: const Color(0xFFBDBDBD), fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.attach_file, color: Color(0xFF5B8C51), size: 22),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF5B8C51), 
                shape: BoxShape.circle
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

// Screen 2: Chat List Screen (Your Messages!)
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int _currentIndex = 0;
  final Color darkTextColor = const Color(0xFF1B1E28);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 120,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 24), // Moved RIGHT slightly
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your',
                style: GoogleFonts.inter(
                  color: darkTextColor,
                  fontSize: 22, // Reduced size
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                'Messages!',
                style: GoogleFonts.inter(
                  color: darkTextColor,
                  fontSize: 24, // Reduced size
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Circular Back Button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                width: 45,
                height: 45,
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F7F9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.chevron_left, color: darkTextColor, size: 28),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  ),
                ),
              ),
            ),
          ),
          // Circular Search Button
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Container(
                width: 45,
                height: 45,
                decoration: const BoxDecoration(
                  color: Color(0xFFECFFEA),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.search, color: darkTextColor, size: 22),
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IndividualChatScreen()),
              );
            },
            child: _buildChatItem(
              name: 'Plantio AI',
              message: 'How can I help you today?',
              time: 'Now',
              isAI: true,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF5B8E55),
        unselectedItemColor: const Color(0xFF999999),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Colors.white,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 28), activeIcon: Icon(Icons.home, size: 28), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined, size: 28), activeIcon: Icon(Icons.map, size: 28), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline, size: 28), activeIcon: Icon(Icons.people, size: 28), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined, size: 28), activeIcon: Icon(Icons.shopping_bag, size: 28), label: ''),
        ],
      ),
    );
  }

  Widget _buildChatItem({required String name, required String message, required String time, bool isAI = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF5B8C51),
            child: Icon(isAI ? Icons.psychology : Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: darkTextColor)),
                const SizedBox(height: 4),
                Text(message, style: GoogleFonts.inter(color: Colors.grey, fontSize: 14), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}