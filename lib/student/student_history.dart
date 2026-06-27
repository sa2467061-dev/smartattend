import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../session/attendance_model.dart';

class StudentHistoryScreen extends StatefulWidget {
  final VoidCallback? onProfilePressed;
  final String? userId;

  const StudentHistoryScreen({super.key, this.onProfilePressed, this.userId});

  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  String _filter = 'All';

  // ─── CHANGED: returns a Stream instead of a Future ───────────────────────
  Stream<Map<String, dynamic>> _watchHistoryData() {
    if (widget.userId == null) {
      return Stream.value(
          {'records': [], 'present': 0, 'absent': 0, 'rate': 0});
    }

    // Listen to the attendance collection in real-time.
    // Every time any attendance doc for this student changes, the stream
    // emits and we rebuild – so Present / Absent / Rate all update instantly.
    return FirebaseFirestore.instance
        .collection('attendance')
        .where('stud_id', isEqualTo: widget.userId)
        .snapshots()
        .asyncMap((snapshot) async {
      int present = 0;
      int absent = 0;
      final List<Map<String, dynamic>> records = [];

      for (final doc in snapshot.docs) {
        final model = AttendanceModel.fromFirestore(doc);

        String className = model.clsId;
        String locationName = '';
        DateTime? startTime;
        DateTime? endTime;
        bool isPastSession = false;

        try {
          final sessionDoc = await FirebaseFirestore.instance
              .collection('session')
              .doc(model.sesId)
              .get();
          if (sessionDoc.exists) {
            final sData = sessionDoc.data()!;
            locationName = sData['location_name'] ?? '';
            final slot = sData['time_slot'] as Map<String, dynamic>? ?? {};
            if (slot['start'] is Timestamp) {
              startTime = (slot['start'] as Timestamp).toDate();
            }
            if (slot['end'] is Timestamp) {
              endTime = (slot['end'] as Timestamp).toDate();
              isPastSession = DateTime.now().isAfter(endTime!);
            }
          }
        } catch (_) {}

        // Show ALL sessions (ongoing + past) — no skip

        try {
          final classDoc = await FirebaseFirestore.instance
              .collection('classes')
              .doc(model.clsId)
              .get();
          if (classDoc.exists) {
            className = classDoc.data()?['name'] ?? model.clsId;
          }
        } catch (_) {}

        // pending on a PAST session = absent; pending on ongoing = still pending
        final effectiveStatus =
            (model.isPending && isPastSession) ? 'absent' : model.status;

        if (effectiveStatus == 'present') present++;
        if (effectiveStatus == 'absent') absent++;

        records.add({
          'status': effectiveStatus,
          'className': className,
          'locationName': locationName,
          'startTime': startTime,
          'endTime': endTime,
        });
      }

      records.sort((a, b) {
        final aTime = a['startTime'] as DateTime?;
        final bTime = b['startTime'] as DateTime?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      final total = present + absent;
      final rate = total == 0 ? 0 : ((present / total) * 100).round();

      return {
        'records': records,
        'present': present,
        'absent': absent,
        'rate': rate,
      };
    });
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        titleSpacing: 16,
        automaticallyImplyLeading: false,
        title: Row(
          children: const [
            Icon(Icons.domain_verification, color: Color(0xff004ce6), size: 28),
            SizedBox(width: 8),
            Text(
              'SMARTATTEND',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: widget.onProfilePressed,
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xff004ce6),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),

      // ─── CHANGED: StreamBuilder replaces FutureBuilder ───────────────────
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _watchHistoryData(),
        builder: (context, snapshot) {
          // Show loader only on the very first load
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error state if stream fails
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load history.\nPlease try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            );
          }

          final data = snapshot.data ??
              {'records': [], 'present': 0, 'absent': 0, 'rate': 0};

          final allRecords = data['records'] as List<Map<String, dynamic>>;
          final present = data['present'] as int;
          final absent = data['absent'] as int;
          final rate = data['rate'] as int;

          final filtered = _filter == 'Absent'
              ? allRecords.where((r) => r['status'] == 'absent').toList()
              : allRecords;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Attendance History',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff111827)),
              ),
              const SizedBox(height: 16),

              // Summary cards – update automatically when attendance changes
              Row(
                children: [
                  _buildSummaryCard(
                      '$present', 'Present', const Color(0xff16a34a)),
                  const SizedBox(width: 12),
                  _buildSummaryCard(
                      '$absent', 'Absent', const Color(0xffdc2626)),
                  const SizedBox(width: 12),
                  _buildSummaryCard('$rate%', 'Rate', const Color(0xff004ce6)),
                ],
              ),
              const SizedBox(height: 20),

              // Filter tabs
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildFilterTab('All', allRecords.length),
                    _buildFilterTab('Absent', absent),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Records list
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      _filter == 'Absent'
                          ? 'No absent records. Great attendance!'
                          : 'No attendance records yet.',
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    ),
                  ),
                )
              else
                ...filtered.map((record) => _buildRecordCard(record)).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterTab(String label, int count) {
    final isSelected = _filter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? const Color(0xff111827)
                      : Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xff004ce6)
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final status = record['status'] as String;
    final className = record['className'] as String;
    final locationName = record['locationName'] as String;
    final startTime = record['startTime'] as DateTime?;
    final endTime = record['endTime'] as DateTime?;

    final isPresent = status == 'present';
    final isAbsent = status == 'absent';

    final Color barColor = isPresent
        ? const Color(0xff16a34a)
        : isAbsent
            ? const Color(0xffdc2626)
            : Colors.grey;

    final String statusLabel = isPresent
        ? 'Present'
        : isAbsent
            ? 'Absent'
            : 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Left color bar
          Container(
            width: 5,
            height: 80,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Status dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: barColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    className,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xff111827)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  if (startTime != null)
                    Text(
                      _formatDate(startTime),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  if (startTime != null && endTime != null)
                    Text(
                      '${_formatTime(startTime)} – ${_formatTime(endTime)}'
                      '${locationName.isNotEmpty ? ' · $locationName' : ''}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),

          // Status badge
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: barColor.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                    color: barColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
