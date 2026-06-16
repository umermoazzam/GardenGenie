// api_service.dart
import 'dart:convert';
import 'dart:io'; // Required for handling File inside predictImage
import 'package:http/http.dart' as http;
import '../models/product_model.dart'; // Import the model

class ApiService {
  // ✅ UPDATED: Ngrok link replaced with permanent Hugging Face Cloud link
  static const String cloudUrl = 'https://umermoazzam-plantio-backend.hf.space';  
  static const String baseUrl = '$cloudUrl/api';
  static const String rootUrl = cloudUrl;

  // 1. Fetch Products from API
  static Future<List<Product>> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Product.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  // 2. Register
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: Server is currently offline.'};
    }
  }

  // 3. Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // 4. Forgot Password
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'email': email}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // 5. Send Message with userId for persistent chat
  static Future<Map<String, dynamic>> sendMessage({required String message, required String userId}) async {
    try {
      final response = await http.post(
        Uri.parse('$rootUrl/chat'), 
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'message': message,
          'userId': userId,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'reply': "AI Server connection error. Please try again later."};
    }
  }

  // 6. Fetch Chat History from Backend
  static Future<List<dynamic>> getChatHistory(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat-history/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('History load failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching history: $e');
      return [];
    }
  }

  // ✅ Permanent Clear Chat History from MongoDB
  static Future<bool> clearChatHistory(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/chat-history/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error clearing history: $e');
      return false;
    }
  }

  // ✅ NEW ADDITION: Predict Image function to catch deep ML payload parameters
  static Future<Map<String, dynamic>?> predictImage(File imageFile) async {
    try {
      // Direct call target on standard predictive architecture route
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/predict'));
      
      // Inject headers to bypass proxy intercept rules safely during debug cycles
      request.headers.addAll({
        'ngrok-skip-browser-warning': 'true',
      });

      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      
      var response = await request.send();
      if (response.statusCode == 200) {
        var res = await http.Response.fromStream(response);
        return json.decode(res.body); // Returns complete dynamic nested JSON response mapping
      }
      return null;
    } catch (e) {
      print('Error running predictive model inference: $e');
      return null;
    }
  }
}