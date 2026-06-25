import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../session/session_model.dart'; // adjust import path to match your project structure

/// Card for a past (already-ended) session.
///
/// - Student view: shows their own attendance status for that session
///   (present / absent / pending-never-ticked), so they know at a glance
///   whether they need to send proof of absence.
/// - Lecturer view: shows a simple "X / Y attended" summary for the class.
///   Full breakdown (15% absence list, not-ticked list) lives in the
///   session detail screen, not here.
class PastSessionCard extends StatelessWidget {
  final SessionModel session;
  final String className;
  final String userId; // matrix number if student; unused if lecturer
  final String userRole; // 'student' | 'lecturer'
  final int totalEnrolled; // only needed for lecturer view

  const PastSessionCard({
    super.key,
    required this.session,
    required this.className,
    required this.userId,
    required this.userRole,
    this.totalEnrolled = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Colors.grey.shade500, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'PAST SESSION',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  className,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xff111827)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(session.startTime)} \u2022 ${_formatTime(session.startTime)}',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          userRole == 'lecturer'
              ? _LecturerAttendedBadge(sesId: session.sesId, totalEnrolled: totalEnrolled)
              : _StudentStatusBadge(sesId: session.sesId, studId: userId),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

// ==========================================
// Lecturer: "X / Y attended" badge
// ==========================================
class _LecturerAttendedBadge extends StatelessWidget {
  final String sesId;
  final int totalEnrolled;

  const _LecturerAttendedBadge({required this.sesId, required this.totalEnrolled});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('ses_id', isEqualTo: sesId)
          .where('status', isEqualTo: 'present')
          .snapshots(),
      builder: (context, snapshot) {
        final presentCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xff004ce6).withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                '$presentCount/$totalEnrolled',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff004ce6)),
              ),
              const SizedBox(height: 2),
              Text(
                'attended',
                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// Student: own present / absent indicator
// ==========================================
class _StudentStatusBadge extends StatelessWidget {
  final String sesId;
  final String studId;

  const _StudentStatusBadge({required this.sesId, required this.studId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('ses_id', isEqualTo: sesId)
          .where('stud_id', isEqualTo: studId)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        String status = 'pending';
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          status = data['status'] ?? 'pending';
        }

        final isPresent = status == 'present';
        // Note: 'pending' on a past session effectively means the student
        // never ticked in time, so it's treated visually the same as absent.

        final Color color = isPresent ? const Color(0xff16a34a) : const Color(0xffdc2626);
        final IconData icon = isPresent ? Icons.check_circle : Icons.cancel;
        final String label = isPresent ? 'Present' : 'Absent';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        );
      },
    );
  }
}