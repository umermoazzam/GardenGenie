// chat_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'detection_screen.dart';

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
  int _currentIndex = 0; // Same as HomeScreen

  void _onNavBarTapped(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (index == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search Filter Screen is currently disabled')),
      );
    } else if (index == 2) {
      Navigator.pushNamed(context, '/rentals');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/cart');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EDE2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
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
                    color: Colors.black,
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
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF5B8C51)),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const OnboardingScreen(),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF5B8E55),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B8E55).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: const Icon(Icons.crop_free, color: Colors.white, size: 26),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          hoverColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavBarTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF5B8E55),
          unselectedItemColor: const Color(0xFF999999),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 28),
              activeIcon: Icon(Icons.home, size: 28),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined, size: 28),
              activeIcon: Icon(Icons.map, size: 28),
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline, size: 28),
              activeIcon: Icon(Icons.people, size: 28),
              label: 'Rentals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined, size: 28),
              activeIcon: Icon(Icons.shopping_bag, size: 28),
              label: 'Cart',
            ),
          ],
        ),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message, style: GoogleFonts.inter(fontSize: 14, color: Colors.black87)),
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
              decoration: BoxDecoration(color: const Color(0xFFD4E7C5), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(message, style: GoogleFonts.inter(fontSize: 14, color: Colors.black87)),
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
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(24)),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Ask Plantio AI...',
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.inter(color: const Color(0xFFBDBDBD), fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.attach_file, color: Color(0xFF5B8C51)), onPressed: () {}),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: Color(0xFF5B8C51), shape: BoxShape.circle),
            child: const Icon(Icons.mic, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// Screen 2: Chat List Screen
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int _currentIndex = 0;

  void _onNavBarTapped(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (index == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search Filter Screen is currently disabled')),
      );
    } else if (index == 2) {
      Navigator.pushNamed(context, '/rentals');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/cart');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 140,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 40, left: 32),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(color: Colors.black, fontSize: 25, height: 1.1),
              children: [
                const TextSpan(text: 'Your\n'),
                TextSpan(text: 'Messages!', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 25)),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 10, right: 24),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IndividualChatScreen()),
              ),
              child: _buildChatItem(
                name: 'Plantio AI',
                message: 'How can I help you today?',
                time: 'Now',
                status: 'online',
                isAI: true,
                unread: true,
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const OnboardingScreen(),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF5B8E55),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B8E55).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: const Icon(Icons.crop_free, color: Colors.white, size: 26),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          hoverColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavBarTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF5B8E55),
          unselectedItemColor: const Color(0xFF999999),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 28),
              activeIcon: Icon(Icons.home, size: 28),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined, size: 28),
              activeIcon: Icon(Icons.map, size: 28),
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline, size: 28),
              activeIcon: Icon(Icons.people, size: 28),
              label: 'Rentals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined, size: 28),
              activeIcon: Icon(Icons.shopping_bag, size: 28),
              label: 'Cart',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem({
    required String name,
    required String message,
    required String time,
    required String status,
    String? imageUrl,
    required bool unread,
    bool isAI = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: isAI ? const Color(0xFF5B8C51) : Colors.grey[200],
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
            child: isAI ? const Icon(Icons.psychology, color: Colors.white, size: 30) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                const SizedBox(height: 4),
                Text(message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: status == 'typing' ? const Color(0xFF5B8C51) : const Color(0xFF757575))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9E9E9E))),
              if (unread)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Color(0xFF5B8C51), shape: BoxShape.circle),
                  child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// Screen 3: Group Chat Screen
class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({Key? key}) : super(key: key);

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  int _currentIndex = 0;

  void _onNavBarTapped(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (index == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search Filter Screen is currently disabled')),
      );
    } else if (index == 2) {
      Navigator.pushNamed(context, '/rentals');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/cart');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EDE2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Stack(
              children: const [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=6'),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=7'),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plant group 2',
                  style: GoogleFonts.inter(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text('+60 members', style: GoogleFonts.inter(color: const Color(0xFF5B8C51), fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF5B8C51)),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(child: Text('Today', style: GoogleFonts.inter(color: const Color(0xFF9E9E9E), fontSize: 12))),
                const SizedBox(height: 16),
                _buildReceivedMessage(
                  'Has anyone tried the new organic fertilizer?',
                  '9:37',
                  'https://i.pravatar.cc/150?img=8',
                ),
                _buildSentMessage('Yes, it works great for indoor plants!', '9:40'),
                _buildReceivedMessageWithImage(
                  'Check out the results on my Fern',
                  '9:42',
                  'https://i.pravatar.cc/150?img=10',
                  'https://images.unsplash.com/photo-1463320726281-696a485928c7?w=400&h=300&fit=crop',
                ),
              ],
            ),
          ),
          _buildMessageInput(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const OnboardingScreen(),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF5B8E55),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B8E55).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: const Icon(Icons.crop_free, color: Colors.white, size: 26),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          hoverColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavBarTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF5B8E55),
          unselectedItemColor: const Color(0xFF999999),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 28),
              activeIcon: Icon(Icons.home, size: 28),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined, size: 28),
              activeIcon: Icon(Icons.map, size: 28),
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline, size: 28),
              activeIcon: Icon(Icons.people, size: 28),
              label: 'Rentals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined, size: 28),
              activeIcon: Icon(Icons.shopping_bag, size: 28),
              label: 'Cart',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedMessage(String message, String time, String avatarUrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 16, backgroundImage: NetworkImage(avatarUrl)),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message, style: GoogleFonts.inter(fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(time, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9E9E9E))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedMessageWithImage(String message, String time, String avatarUrl, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 16, backgroundImage: NetworkImage(avatarUrl)),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(message, style: GoogleFonts.inter(fontSize: 14, color: Colors.black87)),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                    child: Image.network(imageUrl, width: 200, height: 150, fit: BoxFit.cover),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(time, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9E9E9E))),
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
              decoration: BoxDecoration(color: const Color(0xFFD4E7C5), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(message, style: GoogleFonts.inter(fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(time, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5B8C51))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(24)),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Type your message',
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.inter(color: const Color(0xFFBDBDBD), fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.attach_file, color: Color(0xFF5B8C51)), onPressed: () {}),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: Color(0xFF5B8C51), shape: BoxShape.circle),
            child: const Icon(Icons.mic, color: Colors.white),
          ),
        ],
      ),
    );
  }
}