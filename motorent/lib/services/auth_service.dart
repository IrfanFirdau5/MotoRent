import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthService {
  // TODO: Replace with your actual backend API URL
  static const String baseUrl = 'https://your-api-url.com/api';

  // Login function
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'user': User.fromJson(data['user']),
          'token': data['token'], // For JWT authentication
          'message': 'Login successful',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Invalid email or password',
        };
      } else {
        return {
          'success': false,
          'message': 'Login failed. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Mock login for testing (remove when backend is ready)
  Future<Map<String, dynamic>> mockLogin(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock credentials for testing
    final mockUsers = {
      'customer@test.com': {
        'password': 'customer123',
        'user': User(
          userId: 1,
          name: 'John Doe',
          email: 'customer@test.com',
          phone: '0123456789',
          address: 'Kuching, Sarawak',
          userType: 'customer',
          createdAt: DateTime.now(),
        ),
      },
      'owner@test.com': {
        'password': 'owner123',
        'user': User(
          userId: 2,
          name: 'Ahmad Rentals',
          email: 'owner@test.com',
          phone: '0129876543',
          address: 'Kuching, Sarawak',
          userType: 'owner',
          createdAt: DateTime.now(),
        ),
      },
      'driver@test.com': {
        'password': 'driver123',
        'user': User(
          userId: 3,
          name: 'Ali Driver',
          email: 'driver@test.com',
          phone: '0198765432',
          address: 'Kuching, Sarawak',
          userType: 'driver',
          createdAt: DateTime.now(),
        ),
      },
    };

    if (mockUsers.containsKey(email) && 
        mockUsers[email]!['password'] == password) {
      return {
        'success': true,
        'user': mockUsers[email]!['user'],
        'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        'message': 'Login successful',
      };
    } else {
      return {
        'success': false,
        'message': 'Invalid email or password',
      };
    }
  }

  // Register function (for future use)
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String userType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'address': address,
          'user_type': userType,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'user': User.fromJson(data['user']),
          'message': 'Registration successful',
        };
      } else {
        return {
          'success': false,
          'message': 'Registration failed. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Logout function
  Future<void> logout() async {
    // Clear stored tokens/data
    // Implement token removal logic here
  }
}