// FILE: lib/widgets/booking_location_widget.dart
// ✅ Widget to display booking location information with map preview

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/booking.dart';
import '../utils/location_utils.dart';

class BookingLocationWidget extends StatelessWidget {
  final Booking booking;
  final bool showMap;
  final bool showDirections;

  const BookingLocationWidget({
    Key? key,
    required this.booking,
    this.showMap = true,
    this.showDirections = true,
  }) : super(key: key);

  Future<void> _openGoogleMaps(double lat, double lon, String label) async {
    final url = LocationUtils.generateGoogleMapsUrl(
      latitude: lat,
      longitude: lon,
      label: label,
    );

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openDirections() async {
    if (booking.pickupLatitude == null || booking.pickupLongitude == null) {
      return;
    }

    if (booking.needDriver && 
        booking.dropoffLatitude != null && 
        booking.dropoffLongitude != null) {
      // Show directions from pickup to dropoff
      final url = LocationUtils.generateDirectionsUrl(
        startLat: booking.pickupLatitude!,
        startLon: booking.pickupLongitude!,
        endLat: booking.dropoffLatitude!,
        endLon: booking.dropoffLongitude!,
      );

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      // Just open pickup location
      await _openGoogleMaps(
        booking.pickupLatitude!,
        booking.pickupLongitude!,
        'Pickup Location',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we have location data
    if (!booking.hasCompleteLocationData) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off, color: Colors.grey[400]),
            const SizedBox(width: 12),
            Text(
              'Location information not available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Calculate distance and time if we have both pickup and dropoff
    Map<String, dynamic>? routeInfo;
    if (booking.needDriver && booking.hasCompleteDriverLocationData) {
      routeInfo = LocationUtils.getRouteSummary(
        lat1: booking.pickupLatitude!,
        lon1: booking.pickupLongitude!,
        lat2: booking.dropoffLatitude!,
        lon2: booking.dropoffLongitude!,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFF1E88E5),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Location Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (showDirections)
                  IconButton(
                    icon: const Icon(Icons.directions, color: Color(0xFF1E88E5)),
                    onPressed: _openDirections,
                    tooltip: 'Open in Maps',
                  ),
              ],
            ),
          ),

          // Pickup Location
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.green[700],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Pickup Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _openGoogleMaps(
                    booking.pickupLatitude!,
                    booking.pickupLongitude!,
                    'Pickup Location',
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                booking.pickupLocation ?? 'Location',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.open_in_new,
                              size: 16,
                              color: Color(0xFF1E88E5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          LocationUtils.formatCoordinates(
                            booking.pickupLatitude!,
                            booking.pickupLongitude!,
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dropoff Location (if driver service)
          if (booking.needDriver && booking.hasCompleteDriverLocationData) ...[
            // Distance indicator
            if (routeInfo != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 2,
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.green[700]!,
                                  Colors.blue[700]!,
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.directions_car,
                                  size: 14,
                                  color: Colors.blue[900],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${routeInfo['distance_formatted']} • ${routeInfo['time_formatted']}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.blue[700]!,
                                  Colors.red[700]!,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.flag,
                          color: Colors.red[700],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Drop-off Location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _openGoogleMaps(
                      booking.dropoffLatitude!,
                      booking.dropoffLongitude!,
                      'Drop-off Location',
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  booking.dropoffLocation ?? 'Location',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.open_in_new,
                                size: 16,
                                color: Color(0xFF1E88E5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            LocationUtils.formatCoordinates(
                              booking.dropoffLatitude!,
                              booking.dropoffLongitude!,
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Route Summary Card
            if (routeInfo != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildRouteInfoItem(
                            Icons.straighten,
                            'Distance',
                            routeInfo['distance_formatted'],
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.blue[200],
                          ),
                          _buildRouteInfoItem(
                            Icons.access_time,
                            'Est. Time',
                            routeInfo['time_formatted'],
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.blue[200],
                          ),
                          _buildRouteInfoItem(
                            Icons.navigation,
                            'Direction',
                            routeInfo['direction'],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],

          // Map Preview
          if (showMap)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 200,
                  child: FlutterMap(
                    options: MapOptions(
                      center: LatLng(
                        booking.pickupLatitude!,
                        booking.pickupLongitude!,
                      ),
                      zoom: booking.hasCompleteDriverLocationData ? 12.0 : 14.0,
                      interactiveFlags: InteractiveFlag.none,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.motorent',
                      ),
                      MarkerLayer(
                        markers: [
                          // Pickup marker
                          Marker(
                            point: LatLng(
                              booking.pickupLatitude!,
                              booking.pickupLongitude!,
                            ),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.green,
                              size: 40,
                            ),
                          ),
                          // Dropoff marker (if available)
                          if (booking.hasCompleteDriverLocationData)
                            Marker(
                              point: LatLng(
                                booking.dropoffLatitude!,
                                booking.dropoffLongitude!,
                              ),
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.flag,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                        ],
                      ),
                      // Draw line between pickup and dropoff
                      if (booking.hasCompleteDriverLocationData)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [
                                LatLng(
                                  booking.pickupLatitude!,
                                  booking.pickupLongitude!,
                                ),
                                LatLng(
                                  booking.dropoffLatitude!,
                                  booking.dropoffLongitude!,
                                ),
                              ],
                              strokeWidth: 3,
                              color: const Color(0xFF1E88E5),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRouteInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blue[900]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ),
      ],
    );
  }
}