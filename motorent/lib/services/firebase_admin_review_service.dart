// FILE: lib/services/firebase_admin_review_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

class FirebaseAdminReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _reviewsCollection = 'reviews';

  // Fetch all reviews
  Future<List<Review>> fetchAllReviews() async {
    try {
      final snapshot = await _firestore
          .collection(_reviewsCollection)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['review_id'] = doc.id;
        
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        
        return Review.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load reviews: $e');
    }
  }

  // Delete review
  Future<bool> deleteReview(String reviewId, String vehicleId) async {
    try {
      // Delete the review
      await _firestore.collection(_reviewsCollection).doc(reviewId).delete();
      
      // Recalculate vehicle rating
      await _updateVehicleRatingStats(vehicleId);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update vehicle rating statistics after review deletion
  Future<void> _updateVehicleRatingStats(String vehicleId) async {
    try {
      final reviews = await _firestore
          .collection(_reviewsCollection)
          .where('vehicle_id', isEqualTo: vehicleId)
          .get();
      
      if (reviews.docs.isEmpty) {
        await _firestore.collection('vehicles').doc(vehicleId).update({
          'rating': null,
          'review_count': 0,
        });
        return;
      }

      double totalRating = 0;
      for (var doc in reviews.docs) {
        totalRating += (doc.data()['rating'] as num).toDouble();
      }
      
      final averageRating = totalRating / reviews.docs.length;

      await _firestore.collection('vehicles').doc(vehicleId).update({
        'rating': averageRating,
        'review_count': reviews.docs.length,
      });
    } catch (e) {
    }
  }
}