// FILE: lib/utils/location_utils.dart
// ✅ Utility functions for location calculations and formatting

import 'dart:math';
import 'package:latlong2/latlong.dart';

class LocationUtils {
  // ✅ Calculate distance between two coordinates (Haversine formula)
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadius = 6371; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  // ✅ Calculate distance from LatLng objects
  static double calculateDistanceLatLng({
    required LatLng point1,
    required LatLng point2,
  }) {
    return calculateDistance(
      lat1: point1.latitude,
      lon1: point1.longitude,
      lat2: point2.latitude,
      lon2: point2.longitude,
    );
  }

  // ✅ Format distance for display
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).toStringAsFixed(0)} m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceInKm.toStringAsFixed(0)} km';
    }
  }

  // ✅ Check if a point is within a radius
  static bool isWithinRadius({
    required double centerLat,
    required double centerLon,
    required double pointLat,
    required double pointLon,
    required double radiusInKm,
  }) {
    final distance = calculateDistance(
      lat1: centerLat,
      lon1: centerLon,
      lat2: pointLat,
      lon2: pointLon,
    );
    return distance <= radiusInKm;
  }

  // ✅ Calculate estimated driving time (rough estimate: 50 km/h average)
  static Duration estimateDrivingTime(double distanceInKm) {
    const double averageSpeed = 50.0; // km/h
    final hours = distanceInKm / averageSpeed;
    return Duration(minutes: (hours * 60).round());
  }

  // ✅ Format driving time for display
  static String formatDrivingTime(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes == 0) {
        return '$hours hr';
      } else {
        return '$hours hr $minutes min';
      }
    }
  }

  // ✅ Get estimated driving info (distance + time)
  static Map<String, String> getEstimatedDrivingInfo({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final distance = calculateDistance(
      lat1: lat1,
      lon1: lon1,
      lat2: lat2,
      lon2: lon2,
    );
    final time = estimateDrivingTime(distance);

    return {
      'distance': formatDistance(distance),
      'time': formatDrivingTime(time),
      'distance_km': distance.toStringAsFixed(2),
      'time_minutes': time.inMinutes.toString(),
    };
  }

  // ✅ Calculate center point between two coordinates
  static LatLng calculateMidpoint({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLon = _toRadians(lon2 - lon1);

    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);
    final lon1Rad = _toRadians(lon1);

    final bx = cos(lat2Rad) * cos(dLon);
    final by = cos(lat2Rad) * sin(dLon);

    final lat3 = atan2(
      sin(lat1Rad) + sin(lat2Rad),
      sqrt((cos(lat1Rad) + bx) * (cos(lat1Rad) + bx) + by * by),
    );

    final lon3 = lon1Rad + atan2(by, cos(lat1Rad) + bx);

    return LatLng(
      _toDegrees(lat3),
      _toDegrees(lon3),
    );
  }

  // ✅ Get bounding box for a center point and radius
  static Map<String, double> getBoundingBox({
    required double centerLat,
    required double centerLon,
    required double radiusInKm,
  }) {
    const double earthRadius = 6371; // km

    final latDelta = (radiusInKm / earthRadius) * (180 / pi);
    final lonDelta = (radiusInKm / (earthRadius * cos(_toRadians(centerLat)))) * (180 / pi);

    return {
      'minLat': centerLat - latDelta,
      'maxLat': centerLat + latDelta,
      'minLon': centerLon - lonDelta,
      'maxLon': centerLon + lonDelta,
    };
  }

  // ✅ Validate coordinates
  static bool isValidCoordinate({
    required double latitude,
    required double longitude,
  }) {
    return latitude >= -90 && latitude <= 90 &&
           longitude >= -180 && longitude <= 180;
  }

  // ✅ Truncate coordinates to specified decimal places
  static LatLng truncateCoordinates(LatLng point, {int decimals = 6}) {
    final factor = pow(10, decimals);
    final lat = (point.latitude * factor).round() / factor;
    final lon = (point.longitude * factor).round() / factor;
    return LatLng(lat, lon);
  }

  // ✅ Format coordinates for display
  static String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  // ✅ Get cardinal direction between two points
  static String getCardinalDirection({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLon = _toRadians(lon2 - lon1);
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);

    final y = sin(dLon) * cos(lat2Rad);
    final x = cos(lat1Rad) * sin(lat2Rad) -
        sin(lat1Rad) * cos(lat2Rad) * cos(dLon);

    final bearing = atan2(y, x);
    final degrees = _toDegrees(bearing);
    final normalizedDegrees = (degrees + 360) % 360;

    if (normalizedDegrees >= 337.5 || normalizedDegrees < 22.5) {
      return 'North';
    } else if (normalizedDegrees >= 22.5 && normalizedDegrees < 67.5) {
      return 'Northeast';
    } else if (normalizedDegrees >= 67.5 && normalizedDegrees < 112.5) {
      return 'East';
    } else if (normalizedDegrees >= 112.5 && normalizedDegrees < 157.5) {
      return 'Southeast';
    } else if (normalizedDegrees >= 157.5 && normalizedDegrees < 202.5) {
      return 'South';
    } else if (normalizedDegrees >= 202.5 && normalizedDegrees < 247.5) {
      return 'Southwest';
    } else if (normalizedDegrees >= 247.5 && normalizedDegrees < 292.5) {
      return 'West';
    } else {
      return 'Northwest';
    }
  }

  // ✅ Calculate estimated fuel cost (rough estimate)
  static double estimateFuelCost({
    required double distanceInKm,
    double fuelPricePerLiter = 2.05, // RM per liter (Malaysia average)
    double fuelConsumption = 8.0, // liters per 100 km
  }) {
    final litersUsed = (distanceInKm / 100) * fuelConsumption;
    return litersUsed * fuelPricePerLiter;
  }

  // ✅ Format fuel cost for display
  static String formatFuelCost(double cost) {
    return 'RM ${cost.toStringAsFixed(2)}';
  }

  // ✅ Get route summary (distance, time, estimated cost)
  static Map<String, dynamic> getRouteSummary({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
    double fuelPricePerLiter = 2.05,
    double fuelConsumption = 8.0,
  }) {
    final distance = calculateDistance(
      lat1: lat1,
      lon1: lon1,
      lat2: lat2,
      lon2: lon2,
    );

    final time = estimateDrivingTime(distance);
    final fuelCost = estimateFuelCost(
      distanceInKm: distance,
      fuelPricePerLiter: fuelPricePerLiter,
      fuelConsumption: fuelConsumption,
    );
    final direction = getCardinalDirection(
      lat1: lat1,
      lon1: lon1,
      lat2: lat2,
      lon2: lon2,
    );

    return {
      'distance_km': distance,
      'distance_formatted': formatDistance(distance),
      'time_duration': time,
      'time_formatted': formatDrivingTime(time),
      'fuel_cost': fuelCost,
      'fuel_cost_formatted': formatFuelCost(fuelCost),
      'direction': direction,
    };
  }

  // ✅ Check if coordinates are approximately equal
  static bool areCoordinatesEqual(
    LatLng point1,
    LatLng point2, {
    double tolerance = 0.0001, // ~11 meters
  }) {
    return (point1.latitude - point2.latitude).abs() < tolerance &&
           (point1.longitude - point2.longitude).abs() < tolerance;
  }

  // ✅ Generate Google Maps URL
  static String generateGoogleMapsUrl({
    required double latitude,
    required double longitude,
    String? label,
  }) {
    final labelParam = label != null ? '($label)' : '';
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude$labelParam';
  }

  // ✅ Generate directions URL (from point A to point B)
  static String generateDirectionsUrl({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  }) {
    return 'https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLon&destination=$endLat,$endLon&travelmode=driving';
  }

  // ✅ Parse coordinates from string
  static LatLng? parseCoordinates(String coordinateString) {
    try {
      final parts = coordinateString.split(',');
      if (parts.length != 2) return null;

      final lat = double.parse(parts[0].trim());
      final lon = double.parse(parts[1].trim());

      if (!isValidCoordinate(latitude: lat, longitude: lon)) {
        return null;
      }

      return LatLng(lat, lon);
    } catch (e) {
      return null;
    }
  }

  // Helper methods
  static double _toRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  static double _toDegrees(double radians) {
    return radians * (180.0 / pi);
  }

  // ✅ Malaysia-specific: Check if coordinates are in Malaysia
  static bool isInMalaysia(double latitude, double longitude) {
    // Rough bounding box for Malaysia
    // Peninsular Malaysia + East Malaysia (Sabah & Sarawak)
    return (latitude >= 0.85 && latitude <= 7.36) &&
           (longitude >= 99.64 && longitude <= 119.27);
  }

  // ✅ Get nearest major city (Malaysia)
  static String getNearestMajaysianCity(double latitude, double longitude) {
    final cities = {
      'Kuala Lumpur': const LatLng(3.1390, 101.6869),
      'George Town': const LatLng(5.4164, 100.3327),
      'Johor Bahru': const LatLng(1.4927, 103.7414),
      'Ipoh': const LatLng(4.5975, 101.0901),
      'Kuching': const LatLng(1.5535, 110.3593),
      'Kota Kinabalu': const LatLng(5.9804, 116.0735),
      'Petaling Jaya': const LatLng(3.1073, 101.6425),
      'Shah Alam': const LatLng(3.0738, 101.5183),
      'Malacca City': const LatLng(2.1896, 102.2501),
      'Seremban': const LatLng(2.7259, 101.9424),
    };

    String nearestCity = 'Unknown';
    double shortestDistance = double.infinity;

    cities.forEach((cityName, cityCoords) {
      final distance = calculateDistance(
        lat1: latitude,
        lon1: longitude,
        lat2: cityCoords.latitude,
        lon2: cityCoords.longitude,
      );

      if (distance < shortestDistance) {
        shortestDistance = distance;
        nearestCity = cityName;
      }
    });

    return nearestCity;
  }

  // ✅ Get region from coordinates (Malaysia)
  static String getMalaysianRegion(double latitude, double longitude) {
    // Peninsular Malaysia
    if (longitude < 104) {
      if (latitude > 6) {
        return 'Northern Peninsular';
      } else if (latitude > 4) {
        return 'Central Peninsular';
      } else {
        return 'Southern Peninsular';
      }
    }
    // East Malaysia
    else {
      if (latitude > 4) {
        return 'Sabah';
      } else {
        return 'Sarawak';
      }
    }
  }
}

// ✅ Extension for easy usage with booking model
extension LocationExtensions on Map<String, dynamic> {
  double? get pickupLatitude => this['pickup_latitude'] as double?;
  double? get pickupLongitude => this['pickup_longitude'] as double?;
  double? get dropoffLatitude => this['dropoff_latitude'] as double?;
  double? get dropoffLongitude => this['dropoff_longitude'] as double?;

  bool get hasPickupCoordinates =>
      pickupLatitude != null && pickupLongitude != null;

  bool get hasDropoffCoordinates =>
      dropoffLatitude != null && dropoffLongitude != null;

  double? distanceToPickup(double userLat, double userLon) {
    if (!hasPickupCoordinates) return null;
    return LocationUtils.calculateDistance(
      lat1: userLat,
      lon1: userLon,
      lat2: pickupLatitude!,
      lon2: pickupLongitude!,
    );
  }

  double? distancePickupToDropoff() {
    if (!hasPickupCoordinates || !hasDropoffCoordinates) return null;
    return LocationUtils.calculateDistance(
      lat1: pickupLatitude!,
      lon1: pickupLongitude!,
      lat2: dropoffLatitude!,
      lon2: dropoffLongitude!,
    );
  }
}