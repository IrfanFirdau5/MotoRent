import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/review.dart';

class ReviewService {
  static const String baseUrl = 'https://your-api-url.com/api';

  // Submit a review
  Future<Map<String, dynamic>> submitReview({
    required int bookingId,
    required int userId,
    required int vehicleId,
    required double rating,
    required String comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'booking_id': bookingId,
          'user_id': userId,
          'vehicle_id': vehicleId,
          'rating': rating,
          'comment': comment,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'review': Review.fromJson(data['review']),
          'message': 'Review submitted successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to submit review',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Fetch reviews for a vehicle
  Future<List<Review>> fetchVehicleReviews(int vehicleId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/vehicle/$vehicleId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Review.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load reviews');
      }
    } catch (e) {
      throw Exception('Error fetching reviews: $e');
    }
  }

  // Check if user has already reviewed a booking
  Future<bool> hasUserReviewed(int bookingId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/booking/$bookingId/exists'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['has_reviewed'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Mock submit review
  Future<Map<String, dynamic>> mockSubmitReview({
    required int bookingId,
    required int userId,
    required int vehicleId,
    required double rating,
    required String comment,
    String? userName,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    final newReview = Review(
      reviewId: DateTime.now().millisecondsSinceEpoch,
      bookingId: bookingId,
      userId: userId,
      vehicleId: vehicleId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
      userName: userName ?? 'John Doe',
    );

    return {
      'success': true,
      'review': newReview,
      'message': 'Review submitted successfully',
    };
  }

  // Mock fetch vehicle reviews
  Future<List<Review>> mockFetchVehicleReviews(int vehicleId) async {
    await Future.delayed(const Duration(seconds: 1));

    return [
      Review(
        reviewId: 1,
        bookingId: 1001,
        userId: 1,
        vehicleId: vehicleId,
        rating: 5.0,
        comment: 'Excellent car! Very clean and comfortable. The owner was very professional and accommodating. Would definitely rent again!',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        userName: 'Sarah Ahmad',
      ),
      Review(
        reviewId: 2,
        bookingId: 1002,
        userId: 2,
        vehicleId: vehicleId,
        rating: 4.0,
        comment: 'Good experience overall. The car was in great condition and drove smoothly. Pick up and drop off was convenient.',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
        userName: 'Michael Tan',
      ),
      Review(
        reviewId: 3,
        bookingId: 1003,
        userId: 3,
        vehicleId: vehicleId,
        rating: 4.5,
        comment: 'Very satisfied with the rental. Car was well-maintained and fuel-efficient. Owner responded quickly to queries.',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        userName: 'Lisa Wong',
      ),
      Review(
        reviewId: 4,
        bookingId: 1004,
        userId: 4,
        vehicleId: vehicleId,
        rating: 5.0,
        comment: 'Perfect for our family trip! Spacious and comfortable. Highly recommend this vehicle and owner.',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        userName: 'David Lee',
      ),
    ];
  }

  // Mock check if user reviewed
  Future<bool> mockHasUserReviewed(int bookingId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // For demo, bookings with odd IDs are reviewed
    return bookingId % 2 == 1;
  }
}