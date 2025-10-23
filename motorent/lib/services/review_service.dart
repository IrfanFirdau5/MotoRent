import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/review.dart';

class ReviewService {
  static const String baseUrl = 'https://your-api-url.com/api';

  // Fetch reviews for a specific vehicle
  Future<List<Review>> fetchVehicleReviews(int vehicleId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/$vehicleId/reviews'),
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

  // Submit a new review
  Future<bool> submitReview({
    required int bookingId,
    required int userId,
    required int vehicleId,
    required int rating,
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

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Error submitting review: $e');
    }
  }

  // Update an existing review
  Future<bool> updateReview({
    required int reviewId,
    required int rating,
    required String comment,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/reviews/$reviewId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'rating': rating,
          'comment': comment,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating review: $e');
    }
  }

  // Delete a review
  Future<bool> deleteReview(int reviewId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/reviews/$reviewId'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting review: $e');
    }
  }

  // Fetch user's own reviews
  Future<List<Review>> fetchUserReviews(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/reviews'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Review.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load user reviews');
      }
    } catch (e) {
      throw Exception('Error fetching user reviews: $e');
    }
  }

  // Mock data for testing
  Future<List<Review>> fetchMockVehicleReviews(int vehicleId) async {
    await Future.delayed(const Duration(seconds: 1));

    return [
      Review(
        reviewId: 1,
        bookingId: 101,
        userId: 1,
        vehicleId: vehicleId,
        userName: 'Ahmad bin Abdullah',
        rating: 5,
        comment: 'Excellent car! Very clean and comfortable. The owner was very professional and helpful. Highly recommend!',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        vehicleName: 'Toyota Vios',
      ),
      Review(
        reviewId: 2,
        bookingId: 102,
        userId: 2,
        vehicleId: vehicleId,
        userName: 'Sarah Lim',
        rating: 4,
        comment: 'Good experience overall. Car was in great condition. Only minor issue was the pickup time was slightly delayed.',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        vehicleName: 'Toyota Vios',
      ),
      Review(
        reviewId: 3,
        bookingId: 103,
        userId: 3,
        vehicleId: vehicleId,
        userName: 'Kumar Raj',
        rating: 5,
        comment: 'Perfect for my family trip! Spacious and fuel efficient. Will definitely rent again.',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        vehicleName: 'Toyota Vios',
      ),
      Review(
        reviewId: 4,
        bookingId: 104,
        userId: 4,
        vehicleId: vehicleId,
        userName: 'Fatimah Hassan',
        rating: 3,
        comment: 'Car was okay but had some minor scratches that weren\'t mentioned. Otherwise it ran fine.',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        vehicleName: 'Toyota Vios',
      ),
      Review(
        reviewId: 5,
        bookingId: 105,
        userId: 5,
        vehicleId: vehicleId,
        userName: 'David Tan',
        rating: 5,
        comment: 'Amazing service! The car was exactly as described. Very smooth rental process.',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        vehicleName: 'Toyota Vios',
      ),
    ];
  }

  Future<List<Review>> fetchMockUserReviews(int userId) async {
    await Future.delayed(const Duration(seconds: 1));

    return [
      Review(
        reviewId: 1,
        bookingId: 101,
        userId: userId,
        vehicleId: 1,
        userName: 'Current User',
        rating: 5,
        comment: 'Excellent car! Very clean and comfortable.',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        vehicleName: 'Toyota Vios',
      ),
      Review(
        reviewId: 2,
        bookingId: 102,
        userId: userId,
        vehicleId: 3,
        userName: 'Current User',
        rating: 4,
        comment: 'Good experience overall. Car was in great condition.',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        vehicleName: 'Perodua Myvi',
      ),
    ];
  }
}