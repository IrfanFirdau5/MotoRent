class Vehicle {
  final int vehicleId;
  final int ownerId;
  final String brand;
  final String model;
  final String licensePlate;
  final double pricePerDay;
  final String description;
  final String availabilityStatus;
  final String imageUrl;
  final DateTime createdAt;
  final String? ownerName;
  final double? rating;
  final int? reviewCount;

  Vehicle({
    required this.vehicleId,
    required this.ownerId,
    required this.brand,
    required this.model,
    required this.licensePlate,
    required this.pricePerDay,
    required this.description,
    required this.availabilityStatus,
    required this.imageUrl,
    required this.createdAt,
    this.ownerName,
    this.rating,
    this.reviewCount,
  });

  // Factory constructor to create a Vehicle from JSON
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleId: json['vehicle_id'] ?? 0,
      ownerId: json['owner_id'] ?? 0,
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      licensePlate: json['license_plate'] ?? '',
      pricePerDay: (json['price_per_day'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      availabilityStatus: json['availability_status'] ?? 'unavailable',
      imageUrl: json['image_url'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      ownerName: json['owner_name'],
      rating: json['rating']?.toDouble(),
      reviewCount: json['review_count'],
    );
  }

  // Method to convert Vehicle to JSON
  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'owner_id': ownerId,
      'brand': brand,
      'model': model,
      'license_plate': licensePlate,
      'price_per_day': pricePerDay,
      'description': description,
      'availability_status': availabilityStatus,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'owner_name': ownerName,
      'rating': rating,
      'review_count': reviewCount,
    };
  }

  bool get isAvailable => availabilityStatus.toLowerCase() == 'available';

  String get fullName => '$brand $model';
}