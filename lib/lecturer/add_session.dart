import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
//import '../session/attendance_model.dart';
import '../session/session_model.dart';

/// Bottom sheet / form that lets a lecturer create a new session for a class.
///
/// On submit:
///   1. Writes a new `session` doc (cls_id, time_slot, geofence, qr_code, qr_expire)
///   2. Pre-seeds one `attendance` doc per enrolled student (status: pending)
///   Both writes happen in a single Firestore batch so they succeed or fail together.
class AddSessionSheet extends StatefulWidget {
  final String classId;

  const AddSessionSheet({super.key, required this.classId});

  @override
  State<AddSessionSheet> createState() => _AddSessionSheetState();
}

class _AddSessionSheetState extends State<AddSessionSheet> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(
    hour: (TimeOfDay.now().hour + 1) % 24,
  );

  LatLng? _pinLocation;
  double _radiusM = 50; // default geofence radius
  GoogleMapController? _mapController;

  bool _isLoadingDefaultLocation = true;
  bool _isSubmitting = false;

  static const double _defaultLat = 3.1390; // fallback if nothing else available
  static const double _defaultLng = 101.6869;

  @override
  void initState() {
    super.initState();
    _loadDefaultPin();
  }

  // Pre-fill the map pin with the class's most recent session location,
  // so the lecturer isn't dropping a pin from scratch every time.
  Future<void> _loadDefaultPin() async {
    try {
      final lastSessionQuery = await FirebaseFirestore.instance
          .collection('session')
          .where('cls_id', isEqualTo: widget.classId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (lastSessionQuery.docs.isNotEmpty) {
        final lastSession = SessionModel.fromFirestore(lastSessionQuery.docs.first);
        setState(() {
          _pinLocation = LatLng(lastSession.geoLat, lastSession.geoLng);
          _radiusM = lastSession.geoRadiusM == 0 ? 50 : lastSession.geoRadiusM;
          _isLoadingDefaultLocation = false;
        });
        return;
      }
    } catch (_) {
      // fall through to GPS / default below
    }

    // No previous session for this class — try device GPS as a starting point.
    try {
      final hasPermission = await _ensureLocationPermission();
      if (hasPermission) {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _pinLocation = LatLng(position.latitude, position.longitude);
          _isLoadingDefaultLocation = false;
        });
        return;
      }
    } catch (_) {
      // fall through to hardcoded default below
    }

    setState(() {
      _pinLocation = const LatLng(_defaultLat, _defaultLng);
      _isLoadingDefaultLocation = false;
    });
  }

  Future<bool> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: _endTime);
    if (picked != null) setState(() => _endTime = picked);
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // Simple unique-ish code for the QR; swap for a more robust generator if needed.
  String _generateQrCode() {
    final rand = Random();
    final chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _submit() async {
    if (_pinLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a location for this session.')),
      );
      return;
    }

    final startDateTime = _combine(_selectedDate, _startTime);
    final endDateTime = _combine(_selectedDate, _endTime);

    if (!endDateTime.isAfter(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Fetch the class doc to get the enrolled students list (matrix numbers)
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .get();

      if (!classDoc.exists) {
        throw 'Class not found.';
      }

      final classData = classDoc.data();
      final List<dynamic> enrolledStud = classData?['enrolled_stud'] ?? [];

      // 2. Build the new session model
      final newSession = SessionModel(
        sesId: '', // assigned by Firestore on write
        clsId: widget.classId,
        createdAt: DateTime.now(),
        startTime: startDateTime,
        endTime: endDateTime,
        geoLat: _pinLocation!.latitude,
        geoLng: _pinLocation!.longitude,
        geoRadiusM: _radiusM,
        qrCode: _generateQrCode(),
        qrExpire: endDateTime, // QR valid for the whole session window
      );

      // 3. Batch write: session doc + one pending attendance doc per student
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      final sessionRef = firestore.collection('session').doc();
      batch.set(sessionRef, newSession.toFirestore());

      for (final matrixNo in enrolledStud) {
        final attendanceRef = firestore.collection('attendance').doc();
        batch.set(attendanceRef, {
          'ses_id': sessionRef.id,
          'cls_id': widget.classId,
          'stud_id': matrixNo,
          'status': 'pending',
          'timestamp': null,
          'proof': null,
        });
      }

      await batch.commit();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session created successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create session: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Session',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff111827)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Set the date, time, and location for attendance tracking.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),

                _buildLabel('Date'),
                _buildPickerTile(
                  icon: Icons.calendar_today_outlined,
                  label: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Start Time'),
                          _buildPickerTile(
                            icon: Icons.schedule,
                            label: _startTime.format(context),
                            onTap: _pickStartTime,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('End Time'),
                          _buildPickerTile(
                            icon: Icons.schedule_outlined,
                            label: _endTime.format(context),
                            onTap: _pickEndTime,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildLabel('Session Location (drag pin to adjust)'),
                const SizedBox(height: 8),
                _buildMapPicker(),
                const SizedBox(height: 16),

                _buildLabel('Geofence Radius: ${_radiusM.toInt()} m'),
                Slider(
                  value: _radiusM,
                  min: 10,
                  max: 200,
                  divisions: 19,
                  activeColor: const Color(0xff004ce6),
                  label: '${_radiusM.toInt()} m',
                  onChanged: (value) => setState(() => _radiusM = value),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff004ce6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Create Session', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xff374151)),
      ),
    );
  }

  Widget _buildPickerTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xfff8f9fa),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPicker() {
    if (_isLoadingDefaultLocation || _pinLocation == null) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xfff8f9fa),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(child: CircularProgressIndicator(color: Color(0xff004ce6))),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 220,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: _pinLocation!, zoom: 17),
          onMapCreated: (controller) => _mapController = controller,
          markers: {
            Marker(
              markerId: const MarkerId('session_location'),
              position: _pinLocation!,
              draggable: true,
              onDragEnd: (newPos) => setState(() => _pinLocation = newPos),
            ),
          },
          circles: {
            Circle(
              circleId: const CircleId('geofence_radius'),
              center: _pinLocation!,
              radius: _radiusM,
              fillColor: const Color(0xff004ce6).withAlpha(40),
              strokeColor: const Color(0xff004ce6),
              strokeWidth: 1,
            ),
          },
          onTap: (newPos) => setState(() => _pinLocation = newPos),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }
}