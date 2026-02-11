import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'api_service.dart'; 
import 'cart_screen.dart'; // ✅ Import CartScreen
import 'rental_services_screen.dart'; // ✅ Import RentalServicesScreen

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
  final String userId;
  const IndividualChatScreen({Key? key, this.userId = "test_user"}) : super(key: key);

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  bool _isDarkMode = false;

  Color get _bgColor => _isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFFFFF);
  Color get _appBarColor => _isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;
  Color get _textColor => _isDarkMode ? Colors.white : const Color(0xFF1B1E28);
  Color get _aiBubbleColor => _isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF7F7F9);
  Color get _userBubbleColor => _isDarkMode ? const Color(0xFF2D4B2D) : const Color(0xFFECFFEA);
  Color get _inputBgColor => _isDarkMode ? const Color(0xFF1F1F1F) : const Color(0xFFF5F5F5);

  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = []; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await ApiService.getChatHistory(widget.userId);
      setState(() {
        _messages.clear();
        if (history.isEmpty) {
          _messages.add({
            'role': 'ai',
            'message': 'Hello! I am Garden Genie. How can I help you today?',
            'time': 'Just now'
          });
        } else {
          for (var item in history) {
            _messages.add({
              'role': item['role'],
              'message': item['message'],
              'time': item['time']
            });
          }
        }
      });
    } catch (e) {
      print("History load error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showClearChatDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _appBarColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('Clear Chat?', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _textColor)),
          content: Text('Are you sure you want to clear all messages permanently?', 
            style: GoogleFonts.inter(color: _textColor)),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Clear chat', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.of(context).pop(); 
                _performClearChat();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performClearChat() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.clearChatHistory(widget.userId); 
      setState(() {
        _messages.clear(); 
      });
    } catch (e) {
      print("Error clearing chat: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
      final data = await ApiService.sendMessage(message: userMessage, userId: widget.userId);
      String aiMessage = data['reply'] ?? "No response from AI.";
      setState(() {
        _messages.add({'role': 'ai', 'message': aiMessage.trim(), 'time': currentTime});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'message': "Sorry, I'm having trouble connecting to the server.", 'time': "Error"});
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _appBarColor,
        elevation: 0,
        toolbarHeight: 85.0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: _isDarkMode ? Colors.white12 : Colors.grey.withOpacity(0.1),
            height: 1.0,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: _textColor, size: 20),
            onPressed: () => Navigator.pop(context),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Plantio AI', style: GoogleFonts.inter(color: _textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                Text('Always active', style: GoogleFonts.inter(color: const Color(0xFF5B8C51), fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: _textColor, size: 22),
              color: _appBarColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'clear') {
                  _showClearChatDialog(); 
                } else if (value == 'theme') {
                  setState(() => _isDarkMode = !_isDarkMode);
                }
              },
              itemBuilder: (BuildContext context) => [
                _buildPopupItem(_isDarkMode ? Icons.light_mode : Icons.dark_mode, _isDarkMode ? "Light Theme" : "Dark Theme", "theme"),
                _buildPopupItem(Icons.info_outline, "Contact info", "info"),
                _buildPopupItem(Icons.check_circle_outline, "Select messages", "select"),
                _buildPopupItem(Icons.notifications_off_outlined, "Mute notifications", "mute"),
                _buildPopupItem(Icons.close, "Close chat", "close"),
                _buildPopupItem(Icons.report_problem_outlined, "Report", "report"),
                _buildPopupItem(Icons.block, "Block", "block"),
                _buildPopupItem(Icons.delete_sweep_outlined, "Clear chat", "clear"), 
                _buildPopupItem(Icons.delete_outline, "Delete chat", "delete"),
              ],
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

  PopupMenuItem<String> _buildPopupItem(IconData icon, String title, String value) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: _textColor, size: 20),
          const SizedBox(width: 12),
          Text(title, style: GoogleFonts.inter(color: _textColor, fontSize: 14)),
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
          const CircleAvatar(radius: 16, backgroundColor: Color(0xFF5B8C51), child: Icon(Icons.psychology, color: Colors.white, size: 16)),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: _aiBubbleColor, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message, style: GoogleFonts.inter(fontSize: 14, color: _textColor)),
                  const SizedBox(height: 4),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(time, style: GoogleFonts.inter(fontSize: 11, color: _isDarkMode ? Colors.white54 : const Color(0xFF9E9E9E))),
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all, size: 14, color: Color(0xFF5B8C51)),
                  ]),
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
              decoration: BoxDecoration(color: _userBubbleColor, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(message, style: GoogleFonts.inter(fontSize: 14, color: _textColor)),
                  const SizedBox(height: 4),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(time, style: GoogleFonts.inter(fontSize: 11, color: _isDarkMode ? Colors.white70 : const Color(0xFF5B8C51))),
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all, size: 14, color: Color(0xFF5B8C51)),
                  ]),
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
                decoration: BoxDecoration(color: _inputBgColor, borderRadius: BorderRadius.circular(30)),
                child: TextField(
                  controller: _messageController,
                  style: GoogleFonts.inter(color: _textColor),
                  onSubmitted: (_) => _handleSend(),
                  decoration: InputDecoration(
                    hintText: 'Type your message', 
                    border: InputBorder.none, 
                    hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14)
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _handleSend,
              child: Container(
                width: 48, height: 48, 
                decoration: const BoxDecoration(color: Color(0xFF5B8C51), shape: BoxShape.circle), 
                child: const Icon(Icons.send, color: Colors.white, size: 22)
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int _currentIndex = 0;
  final Color darkTextColor = const Color(0xFF1B1E28);

  void _onNavBarTapped(int index) {
    if (index == _currentIndex && index == 0) return;

    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    } else if (index == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categories / Shop Screen is currently disabled')),
      );
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const RentalServicesScreen()));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
    }
    
    setState(() => _currentIndex = index);
  }

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
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const IndividualChatScreen(userId: "test_user")));
            },
            child: _buildChatItem(name: 'Plantio AI', message: 'How can I help you today?', time: 'Now', isAI: true),
          ),
        ],
      ),
      // --- UPDATED NAVIGATION BAR TO MATCH HOME SCREEN ---
      bottomNavigationBar: BottomNavigationBar(
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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 28), activeIcon: Icon(Icons.home, size: 28), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined, size: 28), activeIcon: Icon(Icons.map, size: 28), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline, size: 28), activeIcon: Icon(Icons.people, size: 28), label: 'Rentals'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined, size: 28), activeIcon: Icon(Icons.shopping_bag, size: 28), label: 'Cart'),
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