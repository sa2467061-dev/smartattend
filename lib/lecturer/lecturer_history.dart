import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LecturerHistoryScreen extends StatelessWidget {
  final VoidCallback onProfilePressed;
  final String? userId; // Firebase Auth UID

  const LecturerHistoryScreen({
    super.key,
    required this.onProfilePressed,
    this.userId,
  });

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Stream<List<Map<String, dynamic>>> _watchSessions() {
    if (userId == null) return Stream.value([]);

    // Step 1: Watch classes owned by this lecturer
    return FirebaseFirestore.instance
        .collection('classes')
        .where('lect_id', isEqualTo: userId)
        .snapshots()
        .asyncMap((classSnap) async {
      if (classSnap.docs.isEmpty) return [];

      // Build a map of clsId -> {name, classCode, enrolledCount}
      final Map<String, Map<String, dynamic>> classInfo = {};
      for (final doc in classSnap.docs) {
        final d = doc.data();
        classInfo[doc.id] = {
          'name': d['name'] ?? doc.id,
          'classCode': d['class_code'] ?? '',
          'enrolledCount': (d['enrolled_stud'] as List?)?.length ?? 0,
        };
      }

      final classIds = classInfo.keys.toList();

      // Step 2: Fetch all sessions whose cls_id is in this lecturer's classes
      // Firestore whereIn supports up to 30 items
      final List<Map<String, dynamic>> results = [];

      // Process in chunks of 30
      for (int i = 0; i < classIds.length; i += 30) {
        final chunk = classIds.sublist(
            i, i + 30 > classIds.length ? classIds.length : i + 30);

        final sessionSnap = await FirebaseFirestore.instance
            .collection('session')
            .where('cls_id', whereIn: chunk)
            .get();

        for (final doc in sessionSnap.docs) {
          final data = doc.data();
          final slot = data['time_slot'] as Map<String, dynamic>? ?? {};

          DateTime? startTime;
          DateTime? endTime;

          if (slot['start'] is Timestamp) {
            startTime = (slot['start'] as Timestamp).toDate();
          }
          if (slot['end'] is Timestamp) {
            endTime = (slot['end'] as Timestamp).toDate();
          }

          // Only past sessions
          if (endTime == null || DateTime.now().isBefore(endTime)) continue;

          final clsId = data['cls_id'] ?? '';
          final info = classInfo[clsId] ?? {};

          // Count attendance for this session
          final attSnap = await FirebaseFirestore.instance
              .collection('attendance')
              .where('ses_id', isEqualTo: doc.id)
              .get();

          int presentCount = 0;
          final int totalCount = attSnap.docs.length;

          for (final att in attSnap.docs) {
            if ((att.data()['status'] ?? '') == 'present') presentCount++;
          }

          results.add({
            'sesId': doc.id,
            'className': info['name'] ?? clsId,
            'classCode': info['classCode'] ?? '',
            'locationName': data['location_name'] ?? '',
            'startTime': startTime,
            'endTime': endTime,
            'presentCount': presentCount,
            'totalCount': totalCount,
          });
        }
      }

      // Sort newest first
      results.sort((a, b) {
        final aT = a['startTime'] as DateTime?;
        final bT = b['startTime'] as DateTime?;
        if (aT == null && bT == null) return 0;
        if (aT == null) return 1;
        if (bT == null) return -1;
        return bT.compareTo(aT);
      });

      return results;
    });
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
        title: Row(
          children: const [
            Icon(Icons.domain_verification, color: Color(0xff111827), size: 28),
            SizedBox(width: 8),
            Text('SMARTATTEND',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.5)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: onProfilePressed,
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xff111827),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Attendance History',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff111827))),
              const SizedBox(height: 6),
              const Text(
                'Review details and total turnouts of past sessions.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _watchSessions(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error: ${snapshot.error}',
                              style: TextStyle(color: Colors.grey.shade500)));
                    }
                    final sessions = snapshot.data ?? [];
                    if (sessions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off_rounded,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('No past sessions yet.',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 15)),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: sessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) =>
                          _buildSessionCard(context, sessions[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, Map<String, dynamic> s) {
    final int present = s['presentCount'] as int;
    final int total = s['totalCount'] as int;
    final bool isFullHouse = present == total && total > 0;
    final DateTime? start = s['startTime'] as DateTime?;
    final DateTime? end = s['endTime'] as DateTime?;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _SessionStudentListScreen(
            sesId: s['sesId'] as String,
            className: s['className'] as String,
            sessionDate: start != null ? _formatDate(start) : '',
            sessionTime: (start != null && end != null)
                ? '${_formatTime(start)} – ${_formatTime(end)}'
                : '',
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (s['classCode'].toString().isNotEmpty)
                    Text(s['classCode'],
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(s['className'],
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff111827)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  if (start != null)
                    Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(_formatDate(start),
                          style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ]),
                  const SizedBox(height: 4),
                  if (start != null && end != null)
                    Row(children: [
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('${_formatTime(start)} – ${_formatTime(end)}',
                          style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ]),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isFullHouse
                        ? const Color(0xff10b981).withAlpha(20)
                        : const Color(0xffe9ecef),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$present/$total',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isFullHouse
                                  ? const Color(0xff10b981)
                                  : const Color(0xff111827))),
                      const SizedBox(height: 2),
                      Text('Attended',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isFullHouse
                                  ? const Color(0xff10b981)
                                  : Colors.grey.shade600)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('View list',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Student list screen ───────────────────────────────────────────────────────
class _SessionStudentListScreen extends StatelessWidget {
  final String sesId;
  final String className;
  final String sessionDate;
  final String sessionTime;

  const _SessionStudentListScreen({
    required this.sesId,
    required this.className,
    required this.sessionDate,
    required this.sessionTime,
  });

  Stream<List<Map<String, dynamic>>> _watchStudents() {
    return FirebaseFirestore.instance
        .collection('attendance')
        .where('ses_id', isEqualTo: sesId)
        .snapshots()
        .asyncMap((snap) async {
      final List<Map<String, dynamic>> students = [];

      for (final doc in snap.docs) {
        final data = doc.data();
        final studId = data['stud_id'] ?? '';
        String name = studId;

        try {
          final userSnap = await FirebaseFirestore.instance
              .collection('users')
              .where('matrix_no', isEqualTo: studId)
              .limit(1)
              .get();
          if (userSnap.docs.isNotEmpty) {
            name = userSnap.docs.first.data()['name'] ?? studId;
          }
        } catch (_) {}

        students.add({
          'attId': doc.id,
          'studId': studId,
          'name': name,
          'status': data['status'] ?? 'pending',
          'proof': data['proof'],
          'proofReason': data['proof_reason'],
        });
      }

      const order = {'present': 0, 'absent': 1, 'pending': 2};
      students.sort((a, b) =>
          (order[a['status']] ?? 2).compareTo(order[b['status']] ?? 2));

      return students;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(className,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            Text('$sessionDate · $sessionTime',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _watchStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final students = snapshot.data ?? [];
          if (students.isEmpty) {
            return const Center(child: Text('No students enrolled.'));
          }

          final present =
              students.where((s) => s['status'] == 'present').length;
          final absent =
              students.where((s) => s['status'] == 'absent').length;
          final pending =
              students.where((s) => s['status'] == 'pending').length;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  _summaryChip('$present Present', const Color(0xff16a34a)),
                  const SizedBox(width: 8),
                  _summaryChip('$absent Absent', const Color(0xffdc2626)),
                  if (pending > 0) ...[
                    const SizedBox(width: 8),
                    _summaryChip('$pending Pending', Colors.grey),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              ...students.map((s) => _buildStudentTile(context, s)).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStudentTile(BuildContext context, Map<String, dynamic> s) {
    final status = s['status'] as String;
    final proof = s['proof'] as String?;
    final proofReason = s['proofReason'] as String?;
    final hasReason = proofReason != null && proofReason.isNotEmpty;

    final Color color = status == 'present'
        ? const Color(0xff16a34a)
        : status == 'absent'
            ? const Color(0xffdc2626)
            : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withAlpha(20),
              child: Text(
                s['name'].toString().isNotEmpty
                    ? s['name'].toString()[0].toUpperCase()
                    : '?',
                style:
                    TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(s['name'],
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(s['studId'],
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                status[0].toUpperCase() + status.substring(1),
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Absence reason submitted
          if (status == 'absent' && hasReason) ...[
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.description_outlined,
                        size: 14, color: Color(0xff004ce6)),
                    const SizedBox(width: 6),
                    const Text('Absence Reason',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff004ce6))),
                  ]),
                  const SizedBox(height: 6),
                  Text(proofReason!,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700)),
                  if (proof != null && proof.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _showProofImage(context, proof),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          proof,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 60,
                            color: Colors.grey.shade100,
                            child: const Center(
                                child: Text('Image unavailable',
                                    style: TextStyle(color: Colors.grey))),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Tap image to view full size',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400)),
                  ],
                ],
              ),
            ),
          ],

          // Absent but no reason yet
          if (status == 'absent' && !hasReason) ...[
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(children: [
                Icon(Icons.hourglass_empty_rounded,
                    size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text('No reason submitted yet.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade400)),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  void _showProofImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}