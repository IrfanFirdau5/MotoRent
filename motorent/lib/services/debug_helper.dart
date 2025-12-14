// FILE: motorent/lib/services/debug_helper.dart
// CREATE THIS FILE TO DEBUG THE PERMISSION ISSUE

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DebugHelper {
  static Future<void> debugUserPermissions() async {
    print('\n========================================');
    print('🔍 DEBUGGING FIREBASE PERMISSIONS');
    print('========================================\n');

    try {
      // 1. Check if user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        print('❌ ERROR: No user is currently signed in!');
        print('   Solution: Make sure user is logged in before adding vehicle');
        return;
      }

      print('✅ User is authenticated');
      print('   UID: ${currentUser.uid}');
      print('   Email: ${currentUser.email}');
      print('');

      // 2. Check user document in Firestore
      print('📄 Checking user document in Firestore...');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        print('❌ ERROR: User document does not exist in Firestore!');
        print('   Expected path: users/${currentUser.uid}');
        print('   Solution: User document needs to be created during registration');
        return;
      }

      print('✅ User document exists');
      print('   Document ID: ${userDoc.id}');
      print('');

      // 3. Check user data fields
      final userData = userDoc.data()!;
      print('📊 User Data:');
      print('   user_type: ${userData['user_type']}');
      print('   approval_status: ${userData['approval_status']}');
      print('   is_active: ${userData['is_active']}');
      print('   name: ${userData['name']}');
      print('   email: ${userData['email']}');
      print('');

      // 4. Validate user_type
      if (userData['user_type'] != 'owner') {
        print('❌ ERROR: User is not an owner!');
        print('   Current user_type: ${userData['user_type']}');
        print('   Required: "owner"');
        print('   Solution: This user cannot add vehicles');
        return;
      }
      print('✅ User type is "owner"');

      // 5. Validate approval_status
      if (userData['approval_status'] != 'approved') {
        print('❌ ERROR: Owner is not approved!');
        print('   Current approval_status: ${userData['approval_status']}');
        print('   Required: "approved"');
        print('   Solution: Admin needs to approve this owner first');
        return;
      }
      print('✅ Approval status is "approved"');

      // 6. Validate is_active
      if (userData['is_active'] != true) {
        print('❌ ERROR: Owner account is not active!');
        print('   Current is_active: ${userData['is_active']}');
        print('   Required: true');
        print('   Solution: Account needs to be activated');
        return;
      }
      print('✅ Account is active');
      print('');

      // 7. Test Firestore write permission
      print('🔐 Testing Firestore write permissions...');
      print('   Attempting to write to vehicles collection...');
      
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

        print('✅ SUCCESS! Write permission works!');
        print('   A test vehicle was created successfully');
        print('   Check your Firestore console to verify');
        print('');
        print('========================================');
        print('✅ ALL CHECKS PASSED!');
        print('   Vehicle addition should work now.');
        print('========================================\n');

      } catch (writeError) {
        print('❌ ERROR: Write permission failed!');
        print('   Error: $writeError');
        print('');
        print('🔧 POSSIBLE SOLUTIONS:');
        print('   1. Check Firestore Security Rules are published');
        print('   2. Wait 30-60 seconds for rules to propagate');
        print('   3. Make sure you clicked "Publish" in Firebase Console');
        print('   4. Verify rules syntax has no errors');
        print('');
        print('📋 SECURITY RULES CHECKLIST:');
        print('   □ Opened Firebase Console → Firestore → Rules');
        print('   □ Pasted the new security rules');
        print('   □ Clicked "Publish" button');
        print('   □ Waited at least 30 seconds');
        print('   □ No syntax errors shown in console');
        return;
      }

    } catch (e) {
      print('❌ UNEXPECTED ERROR: $e');
      print('   Stack trace might provide more details');
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