import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../session/session_model.dart';

/// Full-screen session creation flow: map fills the background, with a
/// back button + search bar floating at the top, and a fixed-height
/// bottom panel (date/time/location/radius/create) overlapping the map.
///
/// NOTE: this REPLACES the old AddSessionSheet (modal bottom sheet).
/// At the call site, swap:
///   showModalBottomSheet(... builder: (_) => AddSessionSheet(classId: x) ...)
/// for:
///   Navigator.push(context, MaterialPageRoute(builder: (_) => AddSessionScreen(classId: x)))
class AddSessionScreen extends StatefulWidget {
  final String classId;
  const AddSessionScreen({super.key, required this.classId});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime =
      TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24);

  LatLng? _pinLocation;
  double _radiusM = 30; // default sits within the new 10-60 capped range
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  bool _isLoadingDefaultLocation = true;
  bool _isSubmitting = false;
  bool _isSearching = false;
  List<_GeocodeResult> _searchResults = [];
  DateTime? _lastSearchAt; // simple client-side rate guard (Nominatim: max 1 req/sec)

  static const double _defaultLat = 5.261917;
  static const double _defaultLng = 103.165778;
  static const double _minRadius = 10;
  static const double _maxRadius = 60; // capped per "limitkan range geofence"

  @override
  void initState() {
    super.initState();
    _loadDefaultPin();
  }

  @override
  void dispose() {
    _locationNameController.dispose();
    _searchController.dispose();
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
        final lastSession =
            SessionModel.fromFirestore(lastSessionQuery.docs.first);
        setState(() {
          _pinLocation = LatLng(lastSession.geoLat, lastSession.geoLng);
          _radiusM = lastSession.geoRadiusM == 0
              ? 30
              : lastSession.geoRadiusM.clamp(_minRadius, _maxRadius);
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

  // ── Nominatim search ────────────────────────────────────────────────────
  // Per OSM's Nominatim usage policy (https://operations.osmfoundation.org/policies/nominatim/):
  // max 1 request/second, must set a real User-Agent, and must NOT be used
  // for autocomplete-as-you-type. This only fires when the user explicitly
  // submits the search field, never on keystroke.
  Future<void> _runSearch(String query) async {
    if (query.trim().isEmpty) return;

    final now = DateTime.now();
    if (_lastSearchAt != null && now.difference(_lastSearchAt!) < const Duration(seconds: 1)) {
      return; // simple client-side guard against rapid repeat submits
    }
    _lastSearchAt = now;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'json',
        'limit': '5',
      });

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'SmartAttend/1.0 (Flutter app)'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _searchResults = data
              .map((e) => _GeocodeResult(
                    displayName: e['display_name'] as String,
                    lat: double.parse(e['lat'] as String),
                    lon: double.parse(e['lon'] as String),
                  ))
              .toList();
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search failed. Check your connection.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(_GeocodeResult result) {
    final point = LatLng(result.lat, result.lon);
    setState(() {
      _pinLocation = point;
      _searchResults = [];
      _searchController.clear();
    });
    _mapController.move(point, 17);
    FocusScope.of(context).unfocus();
  }

  // ── Pickers ─────────────────────────────────────────────────────────────
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

  // ── Submit ──────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_pinLocation == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please set a location.')));
      return;
    }
    final locationName = _locationNameController.text.trim();
    if (locationName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter a classroom name.')));
      return;
    }
    final startDateTime = _combine(_selectedDate, _startTime);
    final endDateTime = _combine(_selectedDate, _endTime);

    if (!endDateTime.isAfter(startDateTime)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('End time must be after start time.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .get();
      final List<dynamic> enrolledStud = classDoc.data()?['enrolled_stud'] ?? [];

      final newSession = SessionModel(
        sesId: '',
        clsId: widget.classId,
        createdAt: DateTime.now(),
        startTime: startDateTime,
        endTime: endDateTime,
        geoLat: _pinLocation!.latitude,
        geoLng: _pinLocation!.longitude,
        geoRadiusM: _radiusM,
        locationName: locationName,
      );

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final sessionRef = firestore.collection('session').doc();
      batch.set(sessionRef, newSession.toFirestore());

      for (final matrixNo in enrolledStud) {
        batch.set(firestore.collection('attendance').doc(), {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session created!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Fullscreen map background ─────────────────────────────────
          Positioned.fill(child: _buildMap()),

          // ── Top bar: back button + search field ────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 16, 0),
                child: Row(
                  children: [
                    _buildCircleButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _buildSearchField()),
                  ],
                ),
              ),
            ),
          ),

          // ── Search results dropdown ─────────────────────────────────────
          if (_searchResults.isNotEmpty)
            Positioned(
              top: 70,
              left: 64,
              right: 16,
              child: _buildSearchResultsList(),
            ),

          // ── Bottom panel: date/time/location/radius/create ──────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: const Color(0xff111827)),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 3,
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: _runSearch, // fires only on submit, never per keystroke
        decoration: InputDecoration(
          hintText: 'Search for a place...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Icon(Icons.search, color: Colors.grey.shade500, size: 20),
        ),
      ),
    );
  }

  Widget _buildSearchResultsList() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 4,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: _searchResults.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
          itemBuilder: (context, index) {
            final result = _searchResults[index];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xff004ce6)),
              title: Text(
                result.displayName,
                style: const TextStyle(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _selectSearchResult(result),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (_isLoadingDefaultLocation || _pinLocation == null) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _pinLocation!,
        initialZoom: 17,
        onTap: (_, point) => setState(() => _pinLocation = point),
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
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag-handle-style visual cue (decorative; panel itself is fixed-height)
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                _buildLabel('Date'),
                _buildPickerTile(
                  icon: Icons.calendar_today_outlined,
                  label: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  onTap: _pickDate,
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Start'),
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
                        _buildLabel('End'),
                        _buildPickerTile(
                          icon: Icons.schedule_outlined,
                          label: _endTime.format(context),
                          onTap: _pickEndTime,
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                _buildLabel('Location Name'),
                TextField(
                  controller: _locationNameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Room CS-204',
                    filled: true,
                    fillColor: const Color(0xfff8f9fa),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildLabel('Geofence Radius: ${_radiusM.toInt()} m'),
                Slider(
                  value: _radiusM,
                  min: _minRadius,
                  max: _maxRadius,
                  divisions: (_maxRadius - _minRadius).toInt(),
                  activeColor: const Color(0xff004ce6),
                  onChanged: (value) => setState(() => _radiusM = value),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff004ce6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xff374151))),
      );

  Widget _buildPickerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xfff8f9fa),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

class _GeocodeResult {
  final String displayName;
  final double lat;
  final double lon;

  _GeocodeResult({required this.displayName, required this.lat, required this.lon});
}