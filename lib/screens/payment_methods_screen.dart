import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // A. Multi-user security ke liye
import 'package:shimmer/shimmer.dart';

// ==========================================
// 1. PAYMENT METHOD MODEL
// ==========================================
class PaymentMethod {
  final String id;
  final String title;
  final String subtitle;
  final String type;
  bool isDefault;

  PaymentMethod({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.isDefault = false,
  });

  factory PaymentMethod.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return PaymentMethod(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      type: data['type'] ?? 'credit_card',
      isDefault: data['isDefault'] ?? false,
    );
  }
}

// ==========================================
// 2. PAYMENT SERVICE (Business Logic + Security)
// ==========================================
class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // User ID lene ke liye
  final String collectionPath = 'payment_methods';

  // Current User ki ID nikalna
  String get _uid => _auth.currentUser?.uid ?? "guest_user";

  // A. Pro-Link: User-Specific Data Fetching
  Stream<List<PaymentMethod>> getMethods() {
    return _firestore
        .collection(collectionPath)
        .where('userId', isEqualTo: _uid) // Sirf iss user ke cards uthao
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentMethod.fromFirestore(doc))
            .toList());
  }

  // A. Pro-Link: User-Specific Default Selection
  Future<void> setDefault(String id) async {
    var batch = _firestore.batch();
    var snapshots = await _firestore
        .collection(collectionPath)
        .where('userId', isEqualTo: _uid) // Sirf apne cards update karo
        .get();
        
    for (var doc in snapshots.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == id});
    }
    await batch.commit();
  }

  Future<void> deleteMethod(String id) async {
    await _firestore.collection(collectionPath).doc(id).delete();
  }

  // A. Pro-Link: Saving User ID with Card
  Future<void> addMethod(Map<String, dynamic> data) async {
    data['userId'] = _uid; // Card ke sath User ID save karna lazmi hai
    await _firestore.collection(collectionPath).add(data);
  }
}

// ==========================================
// 3. MAIN PAYMENT METHODS SCREEN
// ==========================================
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);
  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final Color primaryGreen = const Color(0xFF5B8E55);
  late PaymentService _paymentService;
  late Stream<List<PaymentMethod>> _methodsStream;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
    _methodsStream = _paymentService.getMethods();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Payment Methods',
            style: GoogleFonts.poppins(
                color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<PaymentMethod>>(
              stream: _methodsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerList();
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                // Local sort to keep default on top
                var methods = snapshot.data!;
                methods.sort((a, b) => b.isDefault ? 1 : -1);

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  itemCount: methods.length,
                  itemBuilder: (context, index) {
                    final method = methods[index];
                    return _buildDismissibleWrapper(method);
                  },
                );
              },
            ),
          ),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Text("No saved methods", style: GoogleFonts.poppins(color: Colors.grey)));
  }

  Widget _buildDismissibleWrapper(PaymentMethod method) {
    return Dismissible(
      key: Key(method.id),
      direction: DismissDirection.endToStart,
      // C. Action Confirmation: Galti se delete hone se bachane ke liye
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white, // Pure White Background Color
            surfaceTintColor: Colors.transparent, // Material 3 Tint overlay prevention
            title: Text(
              "", 
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            content: Text(
              "Are you sure you want to delete this method?", 
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold), // Confirmation text is now bold
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center, // Buttons centered perfectly
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false), 
                child: const Text("Cancel"),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.pop(context, true), 
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (dir) => _paymentService.deleteMethod(method.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      child: GestureDetector(
        onTap: () => _paymentService.setDefault(method.id),
        child: _buildPaymentCard(method),
      ),
    );
  }

  Widget _buildPaymentCard(PaymentMethod method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: method.isDefault ? Border.all(color: primaryGreen, width: 1.5) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(
        children: [
          Icon(method.type == 'visa' ? Icons.credit_card : Icons.account_balance_wallet, color: primaryGreen),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(method.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(method.subtitle, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          if (method.isDefault) Icon(Icons.check_circle, color: primaryGreen, size: 20),
        ],
      ),
    );
  }

  Widget _buildAddButton() => Padding(
        padding: const EdgeInsets.all(24.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCardScreen())),
          child: Text("ADD NEW METHOD", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      );
}

// ==========================================
// 4. ADD CARD SCREEN (With Smart Validation)
// ==========================================
class AddCardScreen extends StatefulWidget {
  const AddCardScreen({Key? key}) : super(key: key);
  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  String _brand = 'credit_card';

  void _detectBrand(String val) {
    setState(() {
      if (val.startsWith('4')) _brand = 'visa';
      else if (val.startsWith('5')) _brand = 'mastercard';
      else _brand = 'credit_card';
    });
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;
    
    // D. Keyboard Handling: Save hote hi keyboard band ho jaye
    FocusScope.of(context).unfocus(); 
    
    setState(() => _isLoading = true);
    try {
      String cleanCardNum = _cardController.text.replaceAll(' ', '');
      String last4 = cleanCardNum.substring(cleanCardNum.length - 4);

      await _paymentService.addMethod({
        'title': '**** **** **** $last4',
        'subtitle': 'Expires ${_expiryController.text}',
        'type': _brand,
        'isDefault': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Add Card", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)), backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _cardController,
                onChanged: _detectBrand,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16), CardFormatter()],
                decoration: InputDecoration(
                  labelText: "Card Number",
                  prefixIcon: Icon(_brand == 'visa' ? Icons.credit_score : Icons.credit_card, color: const Color(0xFF5B8E55)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v != null && v.length < 19) ? "Invalid Card Number" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _expiryController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4), ExpiryFormatter()],
                decoration: InputDecoration(
                  labelText: "Expiry (MM/YY)",
                  prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF5B8E55)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                // B. Expiry Validation: Month 01-12 check
                validator: (v) {
                  if (v == null || v.length < 5) return "Invalid Expiry";
                  int month = int.parse(v.substring(0, 2));
                  if (month < 1 || month > 12) return "Invalid Month (01-12)";
                  return null;
                },
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator(color: Color(0xFF5B8E55))
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B8E55),
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _saveCard,
                      child: const Text("SAVE CARD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }
}

// 5. FORMATTERS
class CardFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue val) {
    var text = val.text.replaceAll(' ', '');
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i != text.length - 1) buffer.write(' ');
    }
    return TextEditingValue(text: buffer.toString(), selection: TextSelection.collapsed(offset: buffer.length));
  }
}

class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue val) {
    var text = val.text.replaceAll('/', '');
    if (text.length > 2) {
      text = "${text.substring(0, 2)}/${text.substring(2)}";
    }
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}