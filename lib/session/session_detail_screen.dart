import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'session_model.dart';

/// Single screen for viewing a session's details, branching its content
/// by role. Reused from the dashboard's CurrentSessionCard and from the
/// session list inside class_detail.dart.
///
/// Student view: geolocation check + QR scan to mark attendance.
/// Lecturer view: live present count, list of students who haven't ticked,
/// list of students at/over 15% absence for this class, and a delete-session action.
class SessionDetailScreen extends StatefulWidget {
  final SessionModel session;
  final String className;
  final String userId; // matrix number (student) or uid (lecturer)
  final String userRole; // 'student' | 'lecturer'

  const SessionDetailScreen({
    super.key,
    required this.session,
    required this.className,
    required this.userId,
    required this.userRole,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final isLecturer = widget.userRole == 'lecturer';

    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: Text(widget.className, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: isLecturer
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xffdc2626)),
                  onPressed: () => _confirmDeleteSession(context),
                ),
              ]
            : null,
      ),
      body: isLecturer
          ? _LecturerSessionBody(session: widget.session)
          : _StudentSessionBody(session: widget.session, studId: widget.userId),
    );
  }

  Future<void> _confirmDeleteSession(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session?'),
        content: const Text(
          'This will permanently delete this session and all its attendance records. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xffdc2626))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final firestore = FirebaseFirestore.instance;

      final attendanceDocs = await firestore
          .collection('attendance')
          .where('ses_id', isEqualTo: widget.session.sesId)
          .get();

      final batch = firestore.batch();
      for (final doc in attendanceDocs.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(firestore.collection('session').doc(widget.session.sesId));
      await batch.commit();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete session: $e')),
      );
    }
  }
}

// ==========================================
// STUDENT VIEW: geolocation + QR check-in
// ==========================================
class _StudentSessionBody extends StatefulWidget {
  final SessionModel session;
  final String studId;

  const _StudentSessionBody({required this.session, required this.studId});

  @override
  State<_StudentSessionBody> createState() => _StudentSessionBodyState();
}

class _StudentSessionBodyState extends State<_StudentSessionBody> {
  bool _isCheckingLocation = false;
  bool _isWithinGeofence = false;
  String? _locationError;
  bool _hasCheckedLocationOnce = false;

  bool _isProcessingScan = false;

  Future<void> _checkGeofence() async {
    setState(() {
      _isCheckingLocation = true;
      _locationError = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Location permission denied. Enable it in settings to check in.';
          _isCheckingLocation = false;
          _hasCheckedLocationOnce = true;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        widget.session.geoLat,
        widget.session.geoLng,
      );

      setState(() {
        _isWithinGeofence = distanceMeters <= widget.session.geoRadiusM;
        _isCheckingLocation = false;
        _hasCheckedLocationOnce = true;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Could not get your location. Make sure GPS is enabled.';
        _isCheckingLocation = false;
        _hasCheckedLocationOnce = true;
      });
    }
  }

  Future<void> _onQrDetected(BarcodeCapture capture) async {
    if (_isProcessingScan) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final scannedValue = barcodes.first.rawValue;
    if (scannedValue == null) return;

    setState(() => _isProcessingScan = true);

    if (!_isWithinGeofence) {
      _showScanResult(false, 'You must be within the classroom area to check in.');
      setState(() => _isProcessingScan = false);
      return;
    }

    if (DateTime.now().isAfter(widget.session.qrExpire)) {
      _showScanResult(false, 'This QR code has expired.');
      setState(() => _isProcessingScan = false);
      return;
    }

    if (scannedValue != widget.session.qrCode) {
      _showScanResult(false, 'Invalid QR code for this session.');
      setState(() => _isProcessingScan = false);
      return;
    }

    try {
      final attendanceQuery = await FirebaseFirestore.instance
          .collection('attendance')
          .where('ses_id', isEqualTo: widget.session.sesId)
          .where('stud_id', isEqualTo: widget.studId)
          .limit(1)
          .get();

      if (attendanceQuery.docs.isEmpty) {
        _showScanResult(false, 'No attendance record found for you in this session.');
        setState(() => _isProcessingScan = false);
        return;
      }

      await attendanceQuery.docs.first.reference.update({
        'status': 'present',
        'timestamp': Timestamp.now(),
      });

      _showScanResult(true, 'Attendance marked successfully!');
    } catch (e) {
      _showScanResult(false, 'Failed to mark attendance: $e');
    } finally {
      if (mounted) setState(() => _isProcessingScan = false);
    }
  }

  void _showScanResult(bool success, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? const Color(0xff16a34a) : const Color(0xffdc2626),
      ),
    );
    if (success) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSessionInfoCard(),
        const SizedBox(height: 24),
        _buildOwnStatusCard(),
        const SizedBox(height: 24),

        const Text(
          'Step 1: Confirm Location',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xff111827)),
        ),
        const SizedBox(height: 10),
        _buildLocationStep(),
        const SizedBox(height: 24),

        const Text(
          'Step 2: Scan QR Code',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xff111827)),
        ),
        const SizedBox(height: 10),
        _buildQrStep(),
      ],
    );
  }

  Widget _buildSessionInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: Color(0xff004ce6)),
              const SizedBox(width: 8),
              Text(widget.session.locationName, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: Color(0xff004ce6)),
              const SizedBox(width: 8),
              Text(
                '${_formatTime(widget.session.startTime)} - ${_formatTime(widget.session.endTime)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOwnStatusCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('ses_id', isEqualTo: widget.session.sesId)
          .where('stud_id', isEqualTo: widget.studId)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        String status = 'pending';
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          status = data['status'] ?? 'pending';
        }

        final isPresent = status == 'present';
        final color = isPresent ? const Color(0xff16a34a) : Colors.grey.shade500;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(isPresent ? Icons.check_circle : Icons.hourglass_empty_rounded, color: color),
              const SizedBox(width: 10),
              Text(
                isPresent ? 'You are marked Present' : 'Not checked in yet',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isCheckingLocation ? null : _checkGeofence,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff004ce6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isCheckingLocation
                ? const SizedBox(
                    height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.my_location_rounded, size: 18),
            label: Text(_isCheckingLocation ? 'Checking...' : 'Check My Location'),
          ),
        ),
        if (_hasCheckedLocationOnce && !_isCheckingLocation) ...[
          const SizedBox(height: 10),
          if (_locationError != null)
            Text(_locationError!, style: const TextStyle(color: Color(0xffdc2626), fontSize: 13))
          else
            Row(
              children: [
                Icon(
                  _isWithinGeofence ? Icons.check_circle : Icons.error_outline,
                  color: _isWithinGeofence ? const Color(0xff16a34a) : const Color(0xffdc2626),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _isWithinGeofence ? 'You are within the classroom area.' : 'You are too far from the classroom.',
                  style: TextStyle(
                    color: _isWithinGeofence ? const Color(0xff16a34a) : const Color(0xffdc2626),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ],
    );
  }

  Widget _buildQrStep() {
    if (!_isWithinGeofence) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xfff8f9fa),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            'Confirm your location first',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 280,
        child: MobileScanner(
          onDetect: _onQrDetected,
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

// ==========================================
// LECTURER VIEW: live monitoring
// ==========================================
class _LecturerSessionBody extends StatelessWidget {
  final SessionModel session;

  const _LecturerSessionBody({required this.session});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSessionInfoCard(),
        const SizedBox(height: 24),
        _buildLiveCountsRow(),
        const SizedBox(height: 28),

        const Text(
          'Not Checked In',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xff111827)),
        ),
        const SizedBox(height: 10),
        _buildNotCheckedInList(),
        const SizedBox(height: 28),

        const Text(
          'Students at \u226515% Absence',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xff111827)),
        ),
        const SizedBox(height: 6),
        Text(
          'Calculated across all sessions held for this class so far.',
          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        _HighAbsenceList(clsId: session.clsId),
      ],
    );
  }

  Widget _buildSessionInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: Color(0xff004ce6)),
              const SizedBox(width: 8),
              Text(session.locationName, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: Color(0xff004ce6)),
              const SizedBox(width: 8),
              Text(
                '${_formatTime(session.startTime)} - ${_formatTime(session.endTime)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.qr_code_2_rounded, size: 18, color: Color(0xff004ce6)),
              const SizedBox(width: 8),
              Text('Code: ${session.qrCode}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCountsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('ses_id', isEqualTo: session.sesId)
          .snapshots(),
      builder: (context, snapshot) {
        int present = 0;
        int pending = 0;
        int total = 0;

        if (snapshot.hasData) {
          total = snapshot.data!.docs.length;
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';
            if (status == 'present') present++;
            if (status == 'pending') pending++;
          }
        }

        return Row(
          children: [
            Expanded(child: _countTile('Present', present, const Color(0xff16a34a))),
            const SizedBox(width: 12),
            Expanded(child: _countTile('Not Ticked', pending, const Color(0xfff59e0b))),
            const SizedBox(width: 12),
            Expanded(child: _countTile('Total', total, const Color(0xff004ce6))),
          ],
        );
      },
    );
  }

  Widget _countTile(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildNotCheckedInList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('ses_id', isEqualTo: session.sesId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text('Everyone has checked in.', style: TextStyle(color: Colors.grey.shade600)),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final studId = data['stud_id'] ?? '';
              final hasProof = (data['proof'] != null) || ((data['proof_reason'] ?? '').toString().isNotEmpty);
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xfffef3c7),
                  child: Icon(Icons.person_outline, color: Color(0xfff59e0b)),
                ),
                title: Text(studId, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: hasProof ? const Text('Proof of absence submitted') : null,
                trailing: hasProof
                    ? const Icon(Icons.attach_file_rounded, size: 18, color: Color(0xff004ce6))
                    : null,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

// ==========================================
// High-absence (>=15%) list, computed across the whole class
// ==========================================
class _HighAbsenceList extends StatelessWidget {
  final String clsId;

  const _HighAbsenceList({required this.clsId});

  Future<List<MapEntry<String, double>>> _computeHighAbsence() async {
    final firestore = FirebaseFirestore.instance;

    final allAttendance = await firestore
        .collection('attendance')
        .where('cls_id', isEqualTo: clsId)
        .get();

    final Map<String, int> totalByStudent = {};
    final Map<String, int> absentByStudent = {};

    for (final doc in allAttendance.docs) {
      final data = doc.data();
      final studId = data['stud_id'] ?? '';
      final status = data['status'] ?? 'pending';

      totalByStudent[studId] = (totalByStudent[studId] ?? 0) + 1;
      if (status == 'absent' || status == 'pending') {
        absentByStudent[studId] = (absentByStudent[studId] ?? 0) + 1;
      }
    }

    final result = <MapEntry<String, double>>[];
    totalByStudent.forEach((studId, total) {
      final absences = absentByStudent[studId] ?? 0;
      final rate = total == 0 ? 0.0 : absences / total;
      if (rate >= 0.15) {
        result.add(MapEntry(studId, rate));
      }
    });

    result.sort((a, b) => b.value.compareTo(a.value));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MapEntry<String, double>>>(
      future: _computeHighAbsence(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
        }

        final list = snapshot.data!;
        if (list.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text('No students currently at or above 15% absence.', style: TextStyle(color: Colors.grey.shade600)),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: list.map((entry) {
              final percentage = (entry.value * 100).toStringAsFixed(0);
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xfffee2e2),
                  child: Icon(Icons.warning_amber_rounded, color: Color(0xffdc2626)),
                ),
                title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: Text(
                  '$percentage% absent',
                  style: const TextStyle(color: Color(0xffdc2626), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}