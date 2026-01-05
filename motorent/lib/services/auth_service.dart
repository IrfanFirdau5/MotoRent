import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  static const String baseUrl = 'https://your-api-url.com/api';
  
  // Firebase instances
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current Firebase user
  firebase_auth.User? get currentFirebaseUser => _firebaseAuth.currentUser;

  // Stream to listen to auth state changes
  Stream<firebase_auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Login with Firebase
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final firebase_auth.UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return {
          'success': false,
          'message': 'Login failed. Please try again.',
        };
      }

      // Get user data from Firestore
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        return {
          'success': false,
          'message': 'User data not found. Please contact support.',
        };
      }

      // Convert Firestore data to User model
      final userData = userDoc.data() as Map<String, dynamic>;
      userData['user_id'] = userDoc.id; // Use Firebase UID as user_id
      
      final User user = User.fromJson(userData);

      // Check if user is active
      if (!user.isActive) {
        await _firebaseAuth.signOut();
        return {
          'success': false,
          'message': 'Your account has been suspended. Please contact support.',
        };
      }

      return {
        'success': true,
        'user': user,
        'token': await userCredential.user!.getIdToken(),
        'message': 'Login successful',
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'wrong-password':
          message = 'Invalid password. Please try again.';
          break;
        case 'invalid-email':
          message = 'Invalid email format.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many login attempts. Please try again later.';
          break;
        default:
          message = 'Login failed: ${e.message}';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Register new user with Firebase
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String userType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      
      // Create user in Firebase Auth
      final firebase_auth.UserCredential userCredential = 
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return {
          'success': false,
          'message': 'Registration failed. Please try again.',
        };
      }


      // Prepare user data for Firestore
      Map<String, dynamic> userData = {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'user_type': userType,
        'created_at': DateTime.now().toIso8601String(),
        'is_active': userType == 'customer' ? true : false, // Auto-approve customers, require approval for drivers/owners
        'profile_image': null,
        'approval_status': userType == 'customer' ? 'approved' : 'pending', // Add this
        'rejection_reason': null, // Add this
      };

      // Add additional data if provided (for driver/owner registration)
      if (additionalData != null) {
        userData.addAll(additionalData);
      }


      // Save user data to Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);


      // Update display name in Firebase Auth
      await userCredential.user!.updateDisplayName(name);

      // Create User model
      userData['user_id'] = userCredential.user!.uid;
      final User user = User.fromJson(userData);

      return {
        'success': true,
        'user': user,
        'message': userType == 'customer' 
            ? 'Registration successful!' 
            : 'Registration submitted! Awaiting approval.',
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'Password is too weak. Use at least 6 characters.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          message = 'Invalid email format.';
          break;
        default:
          message = 'Registration failed: ${e.message}';
      }
      return {
        'success': false,
        'message': message,
      };
    } on FirebaseException catch (e) {
      return {
        'success': false,
        'message': 'Database error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get current user data
  Future<User?> getCurrentUser() async {
    try {
      final firebase_auth.User? firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;

      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) return null;

      final userData = userDoc.data() as Map<String, dynamic>;
      userData['user_id'] = userDoc.id;
      
      return User.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent. Please check your inbox.',
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'invalid-email':
          message = 'Invalid email format.';
          break;
        default:
          message = 'Failed to send reset email: ${e.message}';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'name': name,
        'phone': phone,
        'address': address,
      });

      // Update display name in Firebase Auth
      await _firebaseAuth.currentUser?.updateDisplayName(name);

      return {
        'success': true,
        'message': 'Profile updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update profile: $e',
      };
    }
  }

  // Mock login for testing (keep for backward compatibility)
  Future<Map<String, dynamic>> mockLogin(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));

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
      'admin@test.com': {
        'password': 'admin123',
        'user': User(
          userId: 4,
          name: 'Admin User',
          email: 'admin@test.com',
          phone: '0111111111',
          address: 'Kuching, Sarawak',
          userType: 'admin',
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
}