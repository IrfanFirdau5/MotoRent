// FILE: lib/services/invoice_storage_service.dart
// ✅ NEW: Upload invoices to Firebase Storage and track in Firestore

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class InvoiceStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload invoice to Firebase Storage
  Future<String?> uploadInvoice({
    required File invoiceFile,
    required String bookingId,
  }) async {
    try {
      
      // Create a reference to the storage location
      final fileName = 'invoice_$bookingId.pdf';
      final storageRef = _storage.ref().child('invoices/$fileName');
      
      // Upload the file
      final uploadTask = await storageRef.putFile(invoiceFile);
      
      // Get the download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      
      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  /// Save invoice metadata to Firestore
  Future<bool> saveInvoiceMetadata({
    required String bookingId,
    required String invoiceUrl,
    required String customerId,
    required String ownerId,
  }) async {
    try {
      
      await _firestore.collection('invoices').doc(bookingId).set({
        'booking_id': bookingId,
        'invoice_url': invoiceUrl,
        'customer_id': customerId,
        'owner_id': ownerId,
        'created_at': FieldValue.serverTimestamp(),
      });
      
      // Also update the booking document with invoice URL
      await _firestore.collection('bookings').doc(bookingId).update({
        'invoice_url': invoiceUrl,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get invoice URL for a booking
  Future<String?> getInvoiceUrl(String bookingId) async {
    try {
      final doc = await _firestore.collection('invoices').doc(bookingId).get();
      
      if (doc.exists) {
        return doc.data()?['invoice_url'] as String?;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Download invoice from Firebase Storage
  Future<File?> downloadInvoice(String invoiceUrl, String bookingId) async {
    try {
      
      // Create a temporary file
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/invoice_$bookingId.pdf');
      
      // Download the file
      final ref = _storage.refFromURL(invoiceUrl);
      await ref.writeToFile(tempFile);
      
      return tempFile;
    } catch (e) {
      return null;
    }
  }

  /// Check if invoice exists for a booking
  Future<bool> invoiceExists(String bookingId) async {
    try {
      final doc = await _firestore.collection('invoices').doc(bookingId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}