import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'api_service.dart'; // ✅ Import ApiService

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
  
  // Logic Variables
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = []; 
  bool _isLoading = false;

  // ❌ backendUrl variable removed as requested

  @override
  void initState() {
    super.initState();
    // Welcome Message
    _messages.add({
      'role': 'ai',
      'message': 'Hello! I am Plantio AI. How can I help you with your garden today?',
      'time': 'Just now'
    });
  }

  // ✅ UPDATED: Handle Send Message using ApiService
  Future<void> _handleSend() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text;
    final currentTime = "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}";

    setState(() {
      _messages.add({'role': 'user', 'message': userMessage, 'time': currentTime});
      _isLoading = true;
    });
    _messageController.clear();

    try {
      // ✅ Send user message via ApiService
      final data = await ApiService.sendMessage(message: userMessage);
      
      // Get reply or default message
      String aiMessage = data['reply'] ?? "No response from AI.";

      setState(() {
        _messages.add({
          'role': 'ai',
          'message': aiMessage.trim(),
          'time': currentTime
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'ai',
          'message': "Sorry, I'm having trouble connecting to the server. Please check if your Python backend is running.",
          'time': "Error"
        });
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 32, bottom: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final chat = _messages[index];
                if (chat['role'] == 'ai') {
                  return _buildReceivedMessage(chat['message']!, chat['time']!);
                } else {
                  return _buildSentMessage(chat['message']!, chat['time']!);
                }
              },
            ),
          ),
          if (_isLoading) const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(color: Color(0xFF5B8C51), minHeight: 2),
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
                  controller: _messageController,
                  style: GoogleFonts.inter(color: darkTextColor),
                  onSubmitted: (_) => _handleSend(),
                  decoration: InputDecoration(
                    hintText: 'Type your message',
                    border: InputBorder.none,
                    hintStyle: GoogleFonts.inter(color: const Color(0xFFBDBDBD), fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _handleSend,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF5B8C51), 
                  shape: BoxShape.circle
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Screen 2: Chat List Screen (Unchanged)
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
          padding: const EdgeInsets.only(left: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your', style: GoogleFonts.inter(color: darkTextColor, fontSize: 22, fontWeight: FontWeight.w400)),
              Text('Messages!', style: GoogleFonts.inter(color: darkTextColor, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                width: 45, height: 45,
                decoration: const BoxDecoration(color: Color(0xFFF7F7F9), shape: BoxShape.circle),
                child: IconButton(
                  icon: Icon(Icons.chevron_left, color: darkTextColor, size: 28),
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen())),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Container(
                width: 45, height: 45,
                decoration: const BoxDecoration(color: Color(0xFFECFFEA), shape: BoxShape.circle),
                child: IconButton(icon: Icon(Icons.search, color: darkTextColor, size: 22), onPressed: () {}),
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => const IndividualChatScreen()));
            },
            child: _buildChatItem(name: 'Plantio AI', message: 'How can I help you today?', time: 'Now', isAI: true),
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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 28), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined, size: 28), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline, size: 28), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined, size: 28), label: ''),
        ],
      ),
    );
  }

  Widget _buildChatItem({required String name, required String message, required String time, bool isAI = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          CircleAvatar(radius: 28, backgroundColor: const Color(0xFF5B8C51), child: Icon(isAI ? Icons.psychology : Icons.person, color: Colors.white, size: 30)),
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