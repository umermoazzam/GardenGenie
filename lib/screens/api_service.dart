import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ✅ Base URL updated to your specific IP
  static const String baseUrl = 'http://192.168.18.77:5000/api';
  static const String rootUrl = 'http://192.168.18.77:5000';

  // 1. Register User
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // 2. Login User
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
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

  // 3. Forgot Password
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // 4. Reset Password (Not strictly needed if using Web, but kept for sync)
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'new_password': newPassword,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // 5. Send Chat Message
  static Future<Map<String, dynamic>> sendMessage({required String message}) async {
    try {
      final response = await http.post(
        Uri.parse('$rootUrl/chat'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );
      try {
        final decodedBody = jsonDecode(response.body);
        return decodedBody;
      } catch (e) {
        return {'reply': "Server returned status ${response.statusCode}"};
      }
    } catch (e) {
      return {'reply': "Server connection error: ${e.toString()}"};
    }
  }
}