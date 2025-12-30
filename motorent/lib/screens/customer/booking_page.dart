// FILE: lib/screens/customer/booking_page.dart
// ✅ UPDATED: Integrated OpenStreetMap location picker

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../models/vehicle.dart';
import '../../models/booking.dart';
import '../../services/firebase_booking_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/location_picker_widget.dart';
import 'stripe_payment_page.dart';


class BookingPage extends StatefulWidget {
  final Vehicle vehicle;
  final String userId;

  const BookingPage({
    Key? key,
    required this.vehicle,
    required this.userId,
  }) : super(key: key);

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final FirebaseBookingService _bookingService = FirebaseBookingService();
  final AuthService _authService = AuthService();
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _startDate;
  DateTime? _endDate;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;
  bool _isLoading = false;
  bool _isCheckingAvailability = true;
  
  // Driver hire option
  bool _needDriver = false;
  final double _driverPricePerDay = 50.0;

  // ✅ NEW: Location data
  String _pickupLocationAddress = '';
  LatLng? _pickupLocationCoords;
  
  String _dropoffLocationAddress = '';
  LatLng? _dropoffLocationCoords;

  // Blocked dates
  final List<DateTime> _blockedDates = [];

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _loadBlockedDates();
  }

  Future<void> _loadBlockedDates() async {
    setState(() {
      _isCheckingAvailability = true;
    });

    try {
      setState(() {
        _isCheckingAvailability = false;
      });
    } catch (e) {
      print('Error loading blocked dates: $e');
      setState(() {
        _isCheckingAvailability = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _isDayBlocked(DateTime day) {
    return _blockedDates.any((blockedDate) => isSameDay(blockedDate, day));
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
      if (_startDate == null || _endDate != null) {
        _startDate = selectedDay;
        _endDate = null;
      } else if (selectedDay.isBefore(_startDate!)) {
        _startDate = selectedDay;
      } else {
        _endDate = selectedDay;
      }
    });
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
      _startDate = start;
      _endDate = end;
    });
  }

  int _calculateDays() {
    if (_startDate != null && _endDate != null) {
      return _endDate!.difference(_startDate!).inDays + 1;
    }
    return 0;
  }

  double _calculateTotalPrice() {
    final days = _calculateDays();
    double vehicleTotal = days * widget.vehicle.pricePerDay;
    double driverTotal = _needDriver ? (days * _driverPricePerDay) : 0.0;
    return vehicleTotal + driverTotal;
  }

  double _calculateVehiclePrice() {
    final days = _calculateDays();
    return days * widget.vehicle.pricePerDay;
  }

  double _calculateDriverPrice() {
    if (!_needDriver) return 0.0;
    final days = _calculateDays();
    return days * _driverPricePerDay;
  }

  // ✅ NEW: Open location picker for pickup
  Future<void> _selectPickupLocation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerWidget(
          title: 'Select Pickup Location',
          initialLocation: _pickupLocationCoords,
          initialAddress: _pickupLocationAddress,
          onLocationSelected: (location, address) {
            setState(() {
              _pickupLocationCoords = location;
              _pickupLocationAddress = address;
            });
          },
        ),
      ),
    );
  }

  // ✅ NEW: Open location picker for dropoff
  Future<void> _selectDropoffLocation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerWidget(
          title: 'Select Drop-off Location',
          initialLocation: _dropoffLocationCoords,
          initialAddress: _dropoffLocationAddress,
          onLocationSelected: (location, address) {
            setState(() {
              _dropoffLocationCoords = location;
              _dropoffLocationAddress = address;
            });
          },
        ),
      ),
    );
  }

  Future<void> _handleBooking() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end dates'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ✅ NEW: Validate pickup location (required for all bookings)
    if (_pickupLocationAddress.isEmpty || _pickupLocationCoords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pickup location'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ✅ Validate dropoff location if driver is needed
    if (_needDriver) {
      if (_dropoffLocationAddress.isEmpty || _dropoffLocationCoords == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a drop-off location for driver service'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    if (_startDate!.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start date cannot be in the past'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = await _authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // ✅ Create booking with location coordinates
      final result = await _bookingService.createBooking(
        userId: widget.userId,
        userName: currentUser.name,
        userPhone: currentUser.phone,
        userEmail: currentUser.email,
        vehicleId: widget.vehicle.vehicleId.toString(),
        vehicleName: widget.vehicle.fullName,
        ownerId: widget.vehicle.ownerId,
        startDate: _startDate!,
        endDate: _endDate!,
        totalPrice: _calculateTotalPrice(),
        needDriver: _needDriver,
        driverPrice: _needDriver ? _calculateDriverPrice() : null,
        pickupLocation: _pickupLocationAddress,
        pickupLatitude: _pickupLocationCoords!.latitude,
        pickupLongitude: _pickupLocationCoords!.longitude,
        dropoffLocation: _needDriver ? _dropoffLocationAddress : null,
        dropoffLatitude: _needDriver ? _dropoffLocationCoords?.latitude : null,
        dropoffLongitude: _needDriver ? _dropoffLocationCoords?.longitude : null,
      );

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (result['success']) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StripePaymentPage(
              booking: result['booking'] as Booking,
              vehicle: widget.vehicle,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _calculateDays();
    final vehiclePrice = _calculateVehiclePrice();
    final driverPrice = _calculateDriverPrice();
    final totalPrice = _calculateTotalPrice();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Vehicle'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: _isCheckingAvailability
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withOpacity(0.1),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.directions_car,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.vehicle.fullName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'RM ${widget.vehicle.pricePerDay.toStringAsFixed(2)}/day',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF1E88E5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Instructions
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Rental Period',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to select start date, then tap again to select end date',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Calendar
                  TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    rangeSelectionMode: _rangeSelectionMode,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    selectedDayPredicate: (day) => isSameDay(_startDate, day),
                    rangeStartDay: _startDate,
                    rangeEndDay: _endDate,
                    onDaySelected: _onDaySelected,
                    onRangeSelected: _onRangeSelected,
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    enabledDayPredicate: (day) {
                      return !day.isBefore(DateTime.now().subtract(const Duration(days: 1))) &&
                          !_isDayBlocked(day);
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.orange[300],
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFF1E88E5),
                        shape: BoxShape.circle,
                      ),
                      rangeStartDecoration: const BoxDecoration(
                        color: Color(0xFF1E88E5),
                        shape: BoxShape.circle,
                      ),
                      rangeEndDecoration: const BoxDecoration(
                        color: Color(0xFF1E88E5),
                        shape: BoxShape.circle,
                      ),
                      rangeHighlightColor: const Color(0xFF1E88E5).withOpacity(0.3),
                      disabledDecoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      outsideDaysVisible: false,
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      formatButtonShowsNext: false,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ NEW: Pickup Location Section (Always visible)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Color(0xFF1E88E5),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Pickup Location',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              ' *',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _selectPickupLocation,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _pickupLocationAddress.isEmpty
                                    ? Colors.grey[300]!
                                    : const Color(0xFF1E88E5),
                                width: _pickupLocationAddress.isEmpty ? 1 : 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: _pickupLocationAddress.isEmpty
                                  ? Colors.grey[50]
                                  : Colors.blue[50],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _pickupLocationAddress.isEmpty
                                      ? Icons.add_location
                                      : Icons.edit_location,
                                  color: const Color(0xFF1E88E5),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _pickupLocationAddress.isEmpty
                                            ? 'Tap to select pickup location'
                                            : _pickupLocationAddress,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _pickupLocationAddress.isEmpty
                                              ? Colors.grey[600]
                                              : Colors.black87,
                                          fontWeight: _pickupLocationAddress.isEmpty
                                              ? FontWeight.normal
                                              : FontWeight.w500,
                                        ),
                                      ),
                                      if (_pickupLocationCoords != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Lat: ${_pickupLocationCoords!.latitude.toStringAsFixed(6)}, '
                                          'Lng: ${_pickupLocationCoords!.longitude.toStringAsFixed(6)}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Color(0xFF1E88E5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Driver Option Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _needDriver ? const Color(0xFF1E88E5) : Colors.grey[300]!,
                          width: _needDriver ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E88E5).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.drive_eta,
                                  color: Color(0xFF1E88E5),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Need a Driver?',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'RM ${_driverPricePerDay.toStringAsFixed(2)}/day',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _needDriver,
                                onChanged: (value) {
                                  setState(() {
                                    _needDriver = value;
                                  });
                                },
                                activeColor: const Color(0xFF1E88E5),
                              ),
                            ],
                          ),
                          if (_needDriver) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: Colors.blue[900],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'A professional driver will be assigned to you after booking confirmation.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ✅ NEW: Dropoff Location (only if driver needed)
                  if (_needDriver) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Color(0xFF1E88E5),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Drop-off Location',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                ' *',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _selectDropoffLocation,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _dropoffLocationAddress.isEmpty
                                      ? Colors.grey[300]!
                                      : const Color(0xFF1E88E5),
                                  width: _dropoffLocationAddress.isEmpty ? 1 : 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: _dropoffLocationAddress.isEmpty
                                    ? Colors.grey[50]
                                    : Colors.blue[50],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _dropoffLocationAddress.isEmpty
                                        ? Icons.add_location
                                        : Icons.edit_location,
                                    color: const Color(0xFF1E88E5),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _dropoffLocationAddress.isEmpty
                                              ? 'Tap to select drop-off location'
                                              : _dropoffLocationAddress,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _dropoffLocationAddress.isEmpty
                                                ? Colors.grey[600]
                                                : Colors.black87,
                                            fontWeight: _dropoffLocationAddress.isEmpty
                                                ? FontWeight.normal
                                                : FontWeight.w500,
                                          ),
                                        ),
                                        if (_dropoffLocationCoords != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Lat: ${_dropoffLocationCoords!.latitude.toStringAsFixed(6)}, '
                                            'Lng: ${_dropoffLocationCoords!.longitude.toStringAsFixed(6)}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Color(0xFF1E88E5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Selected Dates Info
                  if (_startDate != null || _endDate != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _startDate != null
                                          ? DateFormat('dd MMM yyyy').format(_startDate!)
                                          : 'Not selected',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.arrow_forward, color: Color(0xFF1E88E5)),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'End Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _endDate != null
                                          ? DateFormat('dd MMM yyyy').format(_endDate!)
                                          : 'Not selected',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (days > 0) ...[
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Vehicle ($days day${days > 1 ? 's' : ''})',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'RM ${vehiclePrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              if (_needDriver) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Driver ($days day${days > 1 ? 's' : ''})',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'RM ${driverPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'RM ${totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E88E5),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),

                  // Book Button
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: (_startDate != null && 
                                    _endDate != null && 
                                    !_isLoading &&
                                    _pickupLocationAddress.isNotEmpty)
                            ? _handleBooking
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                days > 0
                                    ? 'Confirm Booking - RM ${totalPrice.toStringAsFixed(2)}'
                                    : 'Select Dates & Location to Continue',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}