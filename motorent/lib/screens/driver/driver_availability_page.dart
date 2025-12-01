import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../services/driver_service.dart';

class DriverAvailabilityPage extends StatefulWidget {
  final User driver;

  const DriverAvailabilityPage({
    Key? key,
    required this.driver,
  }) : super(key: key);

  @override
  State<DriverAvailabilityPage> createState() => _DriverAvailabilityPageState();
}

class _DriverAvailabilityPageState extends State<DriverAvailabilityPage> {
  final DriverService _driverService = DriverService();
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  Map<DateTime, List<Map<String, dynamic>>> _availableSlots = {};
  List<Map<String, dynamic>> _todaySlots = [];
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final slots = await _driverService.fetchAvailableSlots(widget.driver.userId);
      setState(() {
        _availableSlots = slots;
        _updateTodaySlots();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateTodaySlots() {
    if (_selectedDay != null) {
      final key = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
      _todaySlots = _availableSlots[key] ?? [];
    }
  }

  Future<void> _addTimeSlot() async {
    TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (startTime == null) return;

    if (!mounted) return;

    TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (startTime.hour + 1) % 24,
        minute: startTime.minute,
      ),
    );

    if (endTime == null) return;

    // Convert to DateTime for comparison
    final startDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      startTime.hour,
      startTime.minute,
    );

    final endDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      endTime.hour,
      endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _driverService.addAvailableSlot(
        widget.driver.userId,
        _selectedDay!,
        startTime,
        endTime,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Time slot added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _loadAvailability();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _removeTimeSlot(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Time Slot'),
        content: const Text('Are you sure you want to remove this time slot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _driverService.removeAvailableSlot(
        widget.driver.userId,
        _selectedDay!,
        index,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Time slot removed'),
          backgroundColor: Colors.green,
        ),
      );

      _loadAvailability();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Availability',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // Calendar
                TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 90)),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                      _updateTodaySlots();
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
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
                    markerDecoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  eventLoader: (day) {
                    final key = DateTime(day.year, day.month, day.day);
                    return _availableSlots[key] ?? [];
                  },
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                  ),
                ),
                const Divider(),

                // Selected Date Info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDay != null
                            ? DateFormat('EEEE, dd MMM yyyy').format(_selectedDay!)
                            : 'Select a date',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _addTimeSlot,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Slot'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Time Slots List
                Expanded(
                  child: _todaySlots.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No time slots for this day',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _addTimeSlot,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Time Slot'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _todaySlots.length,
                          itemBuilder: (context, index) {
                            final slot = _todaySlots[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.access_time,
                                    color: Colors.green,
                                  ),
                                ),
                                title: Text(
                                  '${slot['start']} - ${slot['end']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  slot['booked'] == true ? 'Booked' : 'Available',
                                  style: TextStyle(
                                    color: slot['booked'] == true
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ),
                                trailing: slot['booked'] != true
                                    ? IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _removeTimeSlot(index),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}