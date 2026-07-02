import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../session/session_model.dart'; // adjust import path to match your project structure

/// Card for a past (already-ended) session.
///
/// - Student view: shows their own attendance status for that session
///   (present / absent / pending-never-ticked), so they know at a glance
///   whether they need to send proof of absence.
/// - Lecturer view: shows a simple "X / Y attended" summary for the class,
///   plus edit / delete controls for that session.
///
/// NOTE ON ASSUMPTIONS (please check this against your actual project):
///   - Sessions are stored in a Firestore collection named "sessions".
///     (This is the one thing I couldn't confirm from SessionModel, since
///     it only ever receives a DocumentSnapshot — it doesn't know its own
///     collection path. If your collection is named something else,
///     change _sessionsCollection below.)
///   - Times are stored as nested time_slot.start / time_slot.end
///     Timestamps, matching SessionModel.toFirestore() exactly.
class PastSessionCard extends StatelessWidget {
  final SessionModel session;
  final String className;
  final String userId; // matrix number if student; unused if lecturer
  final String userRole; // 'student' | 'lecturer'
  final int totalEnrolled; // only needed for lecturer view

  // Confirmed from Firebase console: collection is named "session" (singular).
  static const String _sessionsCollection = 'session';

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
    final isLecturer = userRole == 'lecturer';

    return Container(
      width: double.infinity,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history,
                            color: Colors.grey.shade500, size: 18),
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
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff111827)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // ---- Bigger, clearer date/time ----
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(session.startTime),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff374151),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(session.startTime),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff374151),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              isLecturer
                  ? _LecturerAttendedBadge(
                      sesId: session.sesId, totalEnrolled: totalEnrolled)
                  : _StudentStatusBadge(sesId: session.sesId, studId: userId),
            ],
          ),

          // ---- Lecturer-only edit / delete controls ----
          if (isLecturer) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditDialog(context),
                  icon: const Icon(Icons.edit,
                      size: 16, color: Color(0xff004ce6)),
                  label: const Text('Edit',
                      style: TextStyle(color: Color(0xff004ce6))),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _showDeleteDialog(context),
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: Color(0xffdc2626)),
                  label: const Text('Delete',
                      style: TextStyle(color: Color(0xffdc2626))),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
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

  // ==========================================
  // Delete flow
  // ==========================================
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete session?'),
        content: Text(
          'This will permanently delete the $className session on '
          '${_formatDate(session.startTime)} at ${_formatTime(session.startTime)}, '
          'along with its attendance records. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deleteSession(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: Color(0xffdc2626))),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSession(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final firestore = FirebaseFirestore.instance;

      // Delete related attendance records first (batched).
      final attendanceDocs = await firestore
          .collection('attendance')
          .where('ses_id', isEqualTo: session.sesId)
          .get();

      final batch = firestore.batch();
      for (final doc in attendanceDocs.docs) {
        batch.delete(doc.reference);
      }
      batch
          .delete(firestore.collection(_sessionsCollection).doc(session.sesId));
      await batch.commit();

      messenger.showSnackBar(
        const SnackBar(content: Text('Session deleted.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete session: $e')),
      );
    }
  }

  // ==========================================
  // Edit flow
  // ==========================================
  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _EditSessionDialog(
        initialDateTime: session.startTime,
        onSave: (newStart) => _updateSession(context, newStart),
      ),
    );
  }

  /// Updates the session's start time, shifting the end time by the same
  /// amount so the session's original duration is preserved (e.g. a
  /// 2-hour class stays 2 hours long, just moved to the new start).
  Future<void> _updateSession(BuildContext context, DateTime newStart) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final duration = session.endTime.difference(session.startTime);
      final newEnd = newStart.add(duration);

      await FirebaseFirestore.instance
          .collection(_sessionsCollection)
          .doc(session.sesId)
          .update({
        'time_slot.start': Timestamp.fromDate(newStart),
        'time_slot.end': Timestamp.fromDate(newEnd),
      });

      messenger.showSnackBar(
        const SnackBar(content: Text('Session updated.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update session: $e')),
      );
    }
  }
}

// ==========================================
// Edit dialog: pick a new date + time
// ==========================================
class _EditSessionDialog extends StatefulWidget {
  final DateTime initialDateTime;
  final ValueChanged<DateTime> onSave;

  const _EditSessionDialog({
    required this.initialDateTime,
    required this.onSave,
  });

  @override
  State<_EditSessionDialog> createState() => _EditSessionDialogState();
}

class _EditSessionDialogState extends State<_EditSessionDialog> {
  late DateTime _date;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDateTime;
    _time = TimeOfDay.fromDateTime(widget.initialDateTime);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit session date & time'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, color: Color(0xff004ce6)),
            title: Text('${_date.day}/${_date.month}/${_date.year}'),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time, color: Color(0xff004ce6)),
            title: Text(_time.format(context)),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _time,
              );
              if (picked != null) setState(() => _time = picked);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final newDateTime = DateTime(
              _date.year,
              _date.month,
              _date.day,
              _time.hour,
              _time.minute,
            );
            Navigator.pop(context);
            widget.onSave(newDateTime);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ==========================================
// Lecturer: "X / Y attended" badge
// ==========================================
class _LecturerAttendedBadge extends StatelessWidget {
  final String sesId;
  final int totalEnrolled;

  const _LecturerAttendedBadge(
      {required this.sesId, required this.totalEnrolled});

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
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xff004ce6)),
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

        final Color color =
            isPresent ? const Color(0xff16a34a) : const Color(0xffdc2626);
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
                style: TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        );
      },
    );
  }
}
