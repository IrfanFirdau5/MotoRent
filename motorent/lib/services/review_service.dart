import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/review.dart';

class ReviewService {
  static const String baseUrl = 'https://your-api-url.com/api';

<<<<<<< HEAD
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
=======
  // Submit a review
  Future<Map<String, dynamic>> submitReview({
    required int bookingId,
    required int userId,
    required int vehicleId,
    required double rating,
>>>>>>> b786decdbafb0777a0d81d51b1c60ee4c902dc48
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

<<<<<<< HEAD
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
=======
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
>>>>>>> b786decdbafb0777a0d81d51b1c60ee4c902dc48
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Review.fromJson(json)).toList();
      } else {
<<<<<<< HEAD
        throw Exception('Failed to load user reviews');
      }
    } catch (e) {
      throw Exception('Error fetching user reviews: $e');
    }
  }

  // Mock data for testing
  Future<List<Review>> fetchMockVehicleReviews(int vehicleId) async {
=======
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
>>>>>>> b786decdbafb0777a0d81d51b1c60ee4c902dc48
    await Future.delayed(const Duration(seconds: 1));

    return [
      Review(
        reviewId: 1,
<<<<<<< HEAD
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
=======
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
>>>>>>> b786decdbafb0777a0d81d51b1c60ee4c902dc48
      ),
    ];
  }

<<<<<<< HEAD
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
=======
  // Mock check if user reviewed
  Future<bool> mockHasUserReviewed(int bookingId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // For demo, bookings with odd IDs are reviewed
    return bookingId % 2 == 1;
>>>>>>> b786decdbafb0777a0d81d51b1c60ee4c902dc48
  }
}