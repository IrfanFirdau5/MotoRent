// Add this as a temporary page or button in your app
// FILE: lib/screens/debug_everything_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DebugEverythingPage extends StatefulWidget {
  const DebugEverythingPage({Key? key}) : super(key: key);

  @override
  State<DebugEverythingPage> createState() => _DebugEverythingPageState();
}

class _DebugEverythingPageState extends State<DebugEverythingPage> {
  String _output = 'Click "Run Full Debug" to start...';
  bool _isLoading = false;

  Future<void> _runFullDebug() async {
    setState(() {
      _isLoading = true;
      _output = 'Running diagnostics...\n';
    });

    final buffer = StringBuffer();
    
    try {
      buffer.writeln('═══════════════════════════════════════');
      buffer.writeln('🔍 COMPLETE FIREBASE DEBUG');
      buffer.writeln('═══════════════════════════════════════\n');

      // Step 1: Check Authentication
      buffer.writeln('1️⃣ AUTHENTICATION CHECK');
      buffer.writeln('─────────────────────────────────────');
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        buffer.writeln('❌ ERROR: No user logged in!');
        setState(() {
          _output = buffer.toString();
          _isLoading = false;
        });
        return;
      }
      
      buffer.writeln('✅ User authenticated');
      buffer.writeln('   UID: ${currentUser.uid}');
      buffer.writeln('   Email: ${currentUser.email}');
      buffer.writeln('');

      // Step 2: Check User Document
      buffer.writeln('2️⃣ USER DOCUMENT CHECK');
      buffer.writeln('─────────────────────────────────────');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        buffer.writeln('❌ ERROR: User document does not exist!');
        buffer.writeln('   Expected path: users/${currentUser.uid}');
        setState(() {
          _output = buffer.toString();
          _isLoading = false;
        });
        return;
      }

      final userData = userDoc.data()!;
      buffer.writeln('✅ User document exists');
      buffer.writeln('   user_type: ${userData['user_type']}');
      buffer.writeln('   approval_status: ${userData['approval_status']}');
      buffer.writeln('   is_active: ${userData['is_active']}');
      buffer.writeln('   name: ${userData['name']}');
      buffer.writeln('');

      // Step 3: Check Vehicles in Firestore
      buffer.writeln('3️⃣ VEHICLES IN FIRESTORE');
      buffer.writeln('─────────────────────────────────────');
      
      // First, get ALL vehicles
      final allVehicles = await FirebaseFirestore.instance
          .collection('vehicles')
          .get();
      
      buffer.writeln('Total vehicles in database: ${allVehicles.docs.length}');
      
      if (allVehicles.docs.isNotEmpty) {
        buffer.writeln('\nAll vehicles:');
        for (var doc in allVehicles.docs) {
          final data = doc.data();
          final ownerMatch = data['owner_id'] == currentUser.uid ? '✅' : '❌';
          buffer.writeln('  $ownerMatch ${data['brand']} ${data['model']}');
          buffer.writeln('     owner_id: ${data['owner_id']}');
          buffer.writeln('     is_deleted: ${data['is_deleted']}');
        }
      }
      buffer.writeln('');

      // Now try to query YOUR vehicles
      buffer.writeln('Querying YOUR vehicles...');
      buffer.writeln('Query: owner_id == ${currentUser.uid}');
      buffer.writeln('Query: is_deleted == false');
      
      try {
        final myVehicles = await FirebaseFirestore.instance
            .collection('vehicles')
            .where('owner_id', isEqualTo: currentUser.uid)
            .where('is_deleted', isEqualTo: false)
            .get();
        
        buffer.writeln('✅ Query successful!');
        buffer.writeln('   Found: ${myVehicles.docs.length} vehicles');
        
        if (myVehicles.docs.isEmpty) {
          buffer.writeln('\n⚠️  No vehicles match your owner_id');
          buffer.writeln('   Your UID: ${currentUser.uid}');
          buffer.writeln('   Check if owner_id in vehicles matches exactly!');
        }
      } catch (e) {
        buffer.writeln('❌ Query failed: $e');
        if (e.toString().contains('index')) {
          buffer.writeln('   ⚠️  Missing Firestore index!');
          buffer.writeln('   Check console for link to create it');
        }
      }
      buffer.writeln('');

      // Step 4: Check Company Drivers
      buffer.writeln('4️⃣ COMPANY DRIVERS IN FIRESTORE');
      buffer.writeln('─────────────────────────────────────');
      
      final allDrivers = await FirebaseFirestore.instance
          .collection('company_drivers')
          .get();
      
      buffer.writeln('Total drivers in database: ${allDrivers.docs.length}');
      
      if (allDrivers.docs.isNotEmpty) {
        buffer.writeln('\nAll drivers:');
        for (var doc in allDrivers.docs) {
          final data = doc.data();
          final ownerMatch = data['owner_id'] == currentUser.uid ? '✅' : '❌';
          buffer.writeln('  $ownerMatch ${data['name']}');
          buffer.writeln('     owner_id: ${data['owner_id']}');
        }
      }
      buffer.writeln('');

      // Try to query YOUR drivers
      buffer.writeln('Querying YOUR drivers...');
      try {
        final myDrivers = await FirebaseFirestore.instance
            .collection('company_drivers')
            .where('owner_id', isEqualTo: currentUser.uid)
            .get();
        
        buffer.writeln('✅ Query successful!');
        buffer.writeln('   Found: ${myDrivers.docs.length} drivers');
        
        if (myDrivers.docs.isEmpty) {
          buffer.writeln('\n⚠️  No drivers match your owner_id');
        }
      } catch (e) {
        buffer.writeln('❌ Query failed: $e');
      }
      buffer.writeln('');

      // Step 5: Test Vehicle Creation Permission
      buffer.writeln('5️⃣ TEST VEHICLE CREATION PERMISSION');
      buffer.writeln('─────────────────────────────────────');
      
      if (userData['user_type'] != 'owner') {
        buffer.writeln('❌ Cannot test: User type is ${userData['user_type']}, not owner');
      } else {
        buffer.writeln('Attempting to create test vehicle...');
        try {
          final testVehicle = {
            'owner_id': currentUser.uid,
            'owner_name': userData['name'],
            'brand': 'TEST',
            'model': 'DEBUG',
            'license_plate': 'TEST${DateTime.now().millisecondsSinceEpoch}',
            'price_per_day': 1.0,
            'description': 'Debug test vehicle',
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
              .add(testVehicle);
          
          buffer.writeln('✅ SUCCESS! Vehicle creation works!');
          buffer.writeln('   A test vehicle was created.');
        } catch (e) {
          buffer.writeln('❌ FAILED: $e');
          if (e.toString().contains('permission-denied')) {
            buffer.writeln('\n🔥 PERMISSION DENIED!');
            buffer.writeln('   This means security rules are blocking you.');
            buffer.writeln('   Check:');
            buffer.writeln('   1. Rules are published');
            buffer.writeln('   2. User type is exactly "owner"');
            buffer.writeln('   3. owner_id matches request.auth.uid');
          }
        }
      }
      buffer.writeln('');

      // Step 6: Test Driver Creation Permission
      buffer.writeln('6️⃣ TEST DRIVER CREATION PERMISSION');
      buffer.writeln('─────────────────────────────────────');
      
      if (userData['user_type'] != 'owner') {
        buffer.writeln('❌ Cannot test: User type is ${userData['user_type']}, not owner');
      } else {
        buffer.writeln('Attempting to create test driver...');
        try {
          final testDriver = {
            'owner_id': currentUser.uid,
            'user_id': null,
            'name': 'Test Driver ${DateTime.now().millisecondsSinceEpoch}',
            'email': 'test${DateTime.now().millisecondsSinceEpoch}@test.com',
            'phone': '0123456789',
            'license_number': 'TEST123',
            'address': 'Test Address',
            'status': 'available',
            'is_active': true,
            'total_jobs': 0,
            'rating': null,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          };
          
          await FirebaseFirestore.instance
              .collection('company_drivers')
              .add(testDriver);
          
          buffer.writeln('✅ SUCCESS! Driver creation works!');
          buffer.writeln('   A test driver was created.');
        } catch (e) {
          buffer.writeln('❌ FAILED: $e');
        }
      }
      buffer.writeln('');

      // Final Summary
      buffer.writeln('═══════════════════════════════════════');
      buffer.writeln('📊 SUMMARY');
      buffer.writeln('═══════════════════════════════════════');
      buffer.writeln('User: ${userData['user_type']} (${userData['name']})');
      buffer.writeln('Vehicles in DB: ${allVehicles.docs.length}');
      buffer.writeln('Drivers in DB: ${allDrivers.docs.length}');
      buffer.writeln('');
      buffer.writeln('Check the output above for any ❌ errors');
      buffer.writeln('═══════════════════════════════════════');

    } catch (e) {
      buffer.writeln('\n❌ UNEXPECTED ERROR: $e');
    }

    setState(() {
      _output = buffer.toString();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Debug'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _runFullDebug,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isLoading ? 'Running...' : 'Run Full Debug'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _output,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.greenAccent,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}