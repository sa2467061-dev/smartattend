import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart'; // Ganti Google Maps
import 'package:latlong2/latlong.dart';      // Ganti Google Maps
import 'package:geolocator/geolocator.dart';
import '../session/session_model.dart';

/// Bottom sheet / form that lets a lecturer create a new session for a class.
class AddSessionSheet extends StatefulWidget {
  final String classId;
  const AddSessionSheet({super.key, required this.classId});

  @override
  State<AddSessionSheet> createState() => _AddSessionSheetState();
}

class _AddSessionSheetState extends State<AddSessionSheet> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24);

  LatLng? _pinLocation;
  double _radiusM = 50;
  final TextEditingController _locationNameController = TextEditingController();

  bool _isLoadingDefaultLocation = true;
  bool _isSubmitting = false;

  static const double _defaultLat = 3.1390;
  static const double _defaultLng = 101.6869;

  @override
  void initState() {
    super.initState();
    _loadDefaultPin();
  }

  @override
  void dispose() {
    _locationNameController.dispose();
    super.dispose();
  }

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
          _locationNameController.text = lastSession.locationName;
          _isLoadingDefaultLocation = false;
        });
        return;
      }
    } catch (_) {}

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
    } catch (_) {}

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

  String _generateQrCode() {
    final rand = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _submit() async {
    if (_pinLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please set a location.')));
      return;
    }
    final locationName = _locationNameController.text.trim();
    if (locationName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a classroom name.')));
      return;
    }
    final startDateTime = _combine(_selectedDate, _startTime);
    final endDateTime = _combine(_selectedDate, _endTime);

    if (!endDateTime.isAfter(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final classDoc = await FirebaseFirestore.instance.collection('classes').doc(widget.classId).get();
      final List<dynamic> enrolledStud = classDoc.data()?['enrolled_stud'] ?? [];

      final newSession = SessionModel(
        sesId: '', clsId: widget.classId, createdAt: DateTime.now(),
        startTime: startDateTime, endTime: endDateTime,
        geoLat: _pinLocation!.latitude, geoLng: _pinLocation!.longitude,
        geoRadiusM: _radiusM, locationName: locationName,
        qrCode: _generateQrCode(), qrExpire: endDateTime,
      );

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final sessionRef = firestore.collection('session').doc();
      batch.set(sessionRef, newSession.toFirestore());

      for (final matrixNo in enrolledStud) {
        batch.set(firestore.collection('attendance').doc(), {
          'ses_id': sessionRef.id, 'cls_id': widget.classId,
          'stud_id': matrixNo, 'status': 'pending',
          'timestamp': null, 'proof': null,
        });
      }
      await batch.commit();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session created!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9, maxChildSize: 0.95, minChildSize: 0.5, expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create Session', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff111827))),
                const SizedBox(height: 6),
                const Text('Set the date, time, and location.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 24),
                
                _buildLabel('Date'),
                _buildPickerTile(icon: Icons.calendar_today_outlined, label: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', onTap: _pickDate),
                const SizedBox(height: 16),
                
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('Start Time'), _buildPickerTile(icon: Icons.schedule, label: _startTime.format(context), onTap: _pickStartTime)])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel('End Time'), _buildPickerTile(icon: Icons.schedule_outlined, label: _endTime.format(context), onTap: _pickEndTime)])),
                ]),
                const SizedBox(height: 20),

                _buildLabel('Classroom / Location Name'),
                TextField(
                  controller: _locationNameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Room CS-204', filled: true, fillColor: const Color(0xfff8f9fa),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),

                _buildLabel('Session Location (drag pin to adjust)'),
                const SizedBox(height: 8),
                _buildMapPicker(), 
                const SizedBox(height: 16),

                _buildLabel('Geofence Radius: ${_radiusM.toInt()} m'),
                Slider(
                  value: _radiusM, min: 10, max: 200, divisions: 19,
                  activeColor: const Color(0xff004ce6),
                  onChanged: (value) => setState(() => _radiusM = value),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff004ce6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Session'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xff374151))));

  Widget _buildPickerTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xfff8f9fa), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [Icon(icon, size: 20, color: Colors.grey.shade600), const SizedBox(width: 10), Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))]),
      ),
    );
  }

  // --- MAP PICKER YANG TELAH DIKEMASKINI ---
  Widget _buildMapPicker() {
    if (_isLoadingDefaultLocation || _pinLocation == null) {
      return Container(height: 220, decoration: BoxDecoration(color: const Color(0xfff8f9fa), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)), child: const Center(child: CircularProgressIndicator()));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: _pinLocation!,
            initialZoom: 17,
            onTap: (_, point) => setState(() => _pinLocation = LatLng(point.latitude, point.longitude)),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.smartattend',
            ),
            CircleLayer(circles: [
              CircleMarker(
                point: _pinLocation!,
                radius: _radiusM,
                useRadiusInMeter: true,
                color: const Color(0xff004ce6).withOpacity(0.2),
                borderColor: const Color(0xff004ce6),
                borderStrokeWidth: 1,
              ),
            ]),
            MarkerLayer(markers: [
              Marker(
                point: _pinLocation!,
                child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}