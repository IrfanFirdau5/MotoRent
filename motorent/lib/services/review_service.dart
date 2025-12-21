// FILE: motorent/lib/services/review_service.dart
// ✅ ENHANCED: Better error handling and logging

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _reviewsCollection = 'reviews';
  final String _vehiclesCollection = 'vehicles';

  // Submit a new review
  Future<Map<String, dynamic>> submitReview({
    required String bookingId,
    required String userId,
    required String vehicleId,
    required double rating,
    required String comment,
    required String userName,
  }) async {
    try {
      print('📝 Submitting review to Firestore:');
      print('   Collection: $_reviewsCollection');
      print('   Booking ID: $bookingId');
      print('   User ID: $userId');
      print('   Vehicle ID: $vehicleId');
      print('   Rating: $rating');
      
      // Check if user has already reviewed this booking
      final existingReview = await _firestore
          .collection(_reviewsCollection)
          .where('booking_id', isEqualTo: bookingId)
          .where('user_id', isEqualTo: userId)
          .get();

      if (existingReview.docs.isNotEmpty) {
        print('⚠️  User has already reviewed this booking');
        return {
          'success': false,
          'message': 'You have already reviewed this booking',
        };
      }

      // Create new review document
      final reviewData = {
        'booking_id': bookingId,
        'user_id': userId,
        'vehicle_id': vehicleId,
        'user_name': userName,
        'rating': rating.toInt(),
        'comment': comment,
        'created_at': FieldValue.serverTimestamp(),
      };

      print('   Creating review document...');
      final docRef = await _firestore.collection(_reviewsCollection).add(reviewData);
      print('✅ Review created with ID: ${docRef.id}');

      // Update vehicle rating statistics
      print('   Updating vehicle rating stats...');
      await _updateVehicleRatingStats(vehicleId);
      print('✅ Vehicle stats updated');

      return {
        'success': true,
        'message': 'Review submitted successfully!',
        'review_id': docRef.id,
      };
    } catch (e) {
      print('❌ Error submitting review: $e');
      return {
        'success': false,
        'message': 'Failed to submit review: $e',
      };
    }
  }

  // Fetch reviews for a specific vehicle
  Future<List<Review>> fetchVehicleReviews(String vehicleId) async {
    try {
      print('🔍 Fetching reviews for vehicle: $vehicleId');
      
      final querySnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('vehicle_id', isEqualTo: vehicleId)
          .orderBy('created_at', descending: true)
          .get();

      print('✅ Found ${querySnapshot.docs.length} reviews');

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['review_id'] = doc.id;
        
        // Handle Timestamp conversion
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp).toDate().toIso8601String();
        }
        
        return Review.fromJson(data);
      }).toList();
    } catch (e) {
      print('❌ Error fetching vehicle reviews: $e');
      throw Exception('Failed to load reviews: $e');
    }
  }

  // Fetch user's own reviews
  Future<List<Review>> fetchUserReviews(String userId) async {
    try {
      print('🔍 Fetching reviews for user: $userId');
      
      final querySnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      print('✅ Found ${querySnapshot.docs.length} reviews');

      // Fetch vehicle names for each review
      final reviews = await Future.wait(querySnapshot.docs.map((doc) async {
        final data = doc.data();
        data['review_id'] = doc.id;
        
        // Fetch vehicle name
        try {
          final vehicleDoc = await _firestore
              .collection(_vehiclesCollection)
              .doc(data['vehicle_id'])
              .get();
          
          if (vehicleDoc.exists) {
            final vehicleData = vehicleDoc.data()!;
            data['vehicle_name'] = '${vehicleData['brand']} ${vehicleData['model']}';
          }
        } catch (e) {
          print('⚠️  Could not fetch vehicle name: $e');
        }
        
        // Handle Timestamp conversion
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp).toDate().toIso8601String();
        }
        
        return Review.fromJson(data);
      }));

      return reviews;
    } catch (e) {
      print('❌ Error fetching user reviews: $e');
      throw Exception('Failed to load reviews: $e');
    }
  }

  // Check if user has reviewed a specific booking
  Future<bool> hasReviewedBooking(String userId, dynamic bookingId) async {
    try {
      final bookingIdStr = bookingId.toString();
      
      final querySnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('user_id', isEqualTo: userId)
          .where('booking_id', isEqualTo: bookingIdStr)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking review status: $e');
      return false;
    }
  }

  // Get review by booking ID
  Future<Review?> getReviewByBooking(String userId, String bookingId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('user_id', isEqualTo: userId)
          .where('booking_id', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      data['review_id'] = doc.id;
      
      if (data['created_at'] is Timestamp) {
        data['created_at'] = (data['created_at'] as Timestamp).toDate().toIso8601String();
      }
      
      return Review.fromJson(data);
    } catch (e) {
      print('❌ Error getting review: $e');
      return null;
    }
  }

  // Update an existing review
  Future<bool> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
    required String vehicleId,
  }) async {
    try {
      print('📝 Updating review: $reviewId');
      
      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'rating': rating,
        'comment': comment,
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Review updated');

      // Update vehicle rating statistics
      await _updateVehicleRatingStats(vehicleId);

      return true;
    } catch (e) {
      print('❌ Error updating review: $e');
      return false;
    }
  }

  // Delete a review
  Future<bool> deleteReview(String reviewId, String vehicleId) async {
    try {
      print('🗑️  Deleting review: $reviewId');
      
      await _firestore.collection(_reviewsCollection).doc(reviewId).delete();

      print('✅ Review deleted');

      // Update vehicle rating statistics
      await _updateVehicleRatingStats(vehicleId);

      return true;
    } catch (e) {
      print('❌ Error deleting review: $e');
      return false;
    }
  }

  // Update vehicle rating statistics
  Future<void> _updateVehicleRatingStats(String vehicleId) async {
    try {
      final reviews = await fetchVehicleReviews(vehicleId);
      
      if (reviews.isEmpty) {
        // No reviews, set rating to null
        await _firestore.collection(_vehiclesCollection).doc(vehicleId).update({
          'rating': null,
          'review_count': 0,
        });
        print('   Vehicle has no reviews - cleared stats');
        return;
      }

      // Calculate average rating
      final totalRating = reviews.fold<int>(0, (sum, review) => sum + review.rating);
      final averageRating = totalRating / reviews.length;

      // Update vehicle document
      await _firestore.collection(_vehiclesCollection).doc(vehicleId).update({
        'rating': averageRating,
        'review_count': reviews.length,
      });
      
      print('   Updated vehicle rating: ${averageRating.toStringAsFixed(1)} (${reviews.length} reviews)');
    } catch (e) {
      print('⚠️  Error updating vehicle stats: $e');
    }
  }

  // Get vehicle rating summary
  Future<Map<String, dynamic>> getVehicleRatingSummary(String vehicleId) async {
    try {
      final reviews = await fetchVehicleReviews(vehicleId);
      
      if (reviews.isEmpty) {
        return {
          'average_rating': 0.0,
          'total_reviews': 0,
          'rating_distribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        };
      }

      // Calculate average
      final totalRating = reviews.fold<int>(0, (sum, review) => sum + review.rating);
      final averageRating = totalRating / reviews.length;

      // Calculate distribution
      Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      for (var review in reviews) {
        distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
      }

      return {
        'average_rating': averageRating,
        'total_reviews': reviews.length,
        'rating_distribution': distribution,
      };
    } catch (e) {
      print('❌ Error getting rating summary: $e');
      return {
        'average_rating': 0.0,
        'total_reviews': 0,
        'rating_distribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      };
    }
  }

  // Stream reviews for real-time updates
  Stream<List<Review>> streamVehicleReviews(String vehicleId) {
    return _firestore
        .collection(_reviewsCollection)
        .where('vehicle_id', isEqualTo: vehicleId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['review_id'] = doc.id;
        
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp).toDate().toIso8601String();
        }
        
        return Review.fromJson(data);
      }).toList();
    });
  }
}