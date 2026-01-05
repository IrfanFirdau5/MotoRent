// FILE: motorent/lib/services/debug_helper.dart
// CREATE THIS FILE TO DEBUG THE PERMISSION ISSUE

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DebugHelper {
  static Future<void> debugUserPermissions() async {

    try {
      // 1. Check if user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        return;
      }


      // 2. Check user document in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        return;
      }


      // 3. Check user data fields
      final userData = userDoc.data()!;

      // 4. Validate user_type
      if (userData['user_type'] != 'owner') {
        return;
      }

      // 5. Validate approval_status
      if (userData['approval_status'] != 'approved') {
        return;
      }

      // 6. Validate is_active
      if (userData['is_active'] != true) {
        return;
      }

      // 7. Test Firestore write permission
      
      try {
        final testData = {
          'owner_id': currentUser.uid,
          'owner_name': userData['name'] ?? 'Test Owner',
          'brand': 'TEST',
          'model': 'DEBUG',
          'license_plate': 'TEST123',
          'price_per_day': 100.0,
          'description': 'This is a test vehicle to check permissions',
          'availability_status': 'available',
          'image_url': 'https://via.placeholder.com/300x200',
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'rating': null,
          'review_count': 0,
          'total_bookings': 0,
          'total_revenue': 0.0,
          'is_deleted': false,
        };

        await FirebaseFirestore.instance
            .collection('vehicles')
            .add(testData);


      } catch (writeError) {
        return;
      }

    } catch (e) {
    }
  }

  // Quick check method that returns actionable advice
  static Future<String> quickCheck() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        return '❌ Not logged in. Please sign in first.';
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        return '❌ User document not found. Registration incomplete.';
      }

      final data = userDoc.data()!;
      
      if (data['user_type'] != 'owner') {
        return '❌ Account is ${data['user_type']}, not owner.';
      }

      if (data['approval_status'] != 'approved') {
        return '❌ Waiting for admin approval (${data['approval_status']}).';
      }

      if (data['is_active'] != true) {
        return '❌ Account is inactive. Contact admin.';
      }

      return '✅ All permissions OK. Ready to add vehicles!';

    } catch (e) {
      return '❌ Error checking permissions: $e';
    }
  }
}