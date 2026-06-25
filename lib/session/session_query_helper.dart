import 'package:cloud_firestore/cloud_firestore.dart';
import 'session_model.dart';

/// Bundles a session with the human-readable name of the class it belongs to,
/// since SessionModel itself doesn't store the class name.
class SessionWithClass {
  final SessionModel session;
  final String className;
  final int totalEnrolled; // size of enrolled_stud for that class, used by lecturer cards

  SessionWithClass({
    required this.session,
    required this.className,
    required this.totalEnrolled,
  });
}

/// Finds the single most relevant current / next / past session across
/// ALL classes a user belongs to (student: enrolled; lecturer: teaching).
///
/// Returns a record with at most one SessionWithClass per slot.
class DashboardSessionResult {
  final SessionWithClass? current;
  final SessionWithClass? next;
  final SessionWithClass? past;

  DashboardSessionResult({this.current, this.next, this.past});
}

class SessionQueryHelper {
  /// userId here is the matrix number for students, or the Firestore doc ID
  /// (uid) for lecturers — matching how `enrolled_stud` and `lect_id` are stored.
  static Future<DashboardSessionResult> fetchDashboardSessions({
    required String userId,
    required String userRole, // 'student' | 'lecturer'
  }) async {
    final firestore = FirebaseFirestore.instance;

    // 1. Find all classes this user belongs to.
    final classQuery = userRole == 'lecturer'
        ? await firestore.collection('classes').where('lect_id', isEqualTo: userId).get()
        : await firestore.collection('classes').where('enrolled_stud', arrayContains: userId).get();

    if (classQuery.docs.isEmpty) {
      return DashboardSessionResult();
    }

    // Map of classId -> (name, enrolledCount) for quick lookup later.
    final Map<String, _ClassInfo> classInfoById = {};
    final List<String> classIds = [];

    for (final doc in classQuery.docs) {
      final data = doc.data();
      classIds.add(doc.id);
      classInfoById[doc.id] = _ClassInfo(
        name: data['name'] ?? 'Untitled Class',
        enrolledCount: (data['enrolled_stud'] as List<dynamic>? ?? []).length,
      );
    }

    // 2. Fetch all sessions belonging to those classes.
    // Firestore 'whereIn' supports up to 30 values; chunk if a user somehow
    // has more classes than that.
    final List<SessionModel> allSessions = [];
    for (final chunk in _chunk(classIds, 30)) {
      final sessionQuery = await firestore
          .collection('session')
          .where('cls_id', whereIn: chunk)
          .get();
      allSessions.addAll(sessionQuery.docs.map(SessionModel.fromFirestore));
    }

    if (allSessions.isEmpty) {
      return DashboardSessionResult();
    }

    final now = DateTime.now();

    // 3. Current: first session where now falls within [start, end].
    SessionModel? current;
    for (final s in allSessions) {
      if (s.isCurrent(now: now)) {
        current = s;
        break;
      }
    }

    // 4. Next: soonest upcoming session (start time in the future), excluding current.
    final upcoming = allSessions.where((s) => s.isUpcoming(now: now)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final SessionModel? next = upcoming.isNotEmpty ? upcoming.first : null;

    // 5. Past: most recently ended session.
    final past = allSessions.where((s) => s.isPast(now: now)).toList()
      ..sort((a, b) => b.endTime.compareTo(a.endTime));
    final SessionModel? mostRecentPast = past.isNotEmpty ? past.first : null;

    SessionWithClass? wrap(SessionModel? s) {
      if (s == null) return null;
      final info = classInfoById[s.clsId];
      return SessionWithClass(
        session: s,
        className: info?.name ?? 'Unknown Class',
        totalEnrolled: info?.enrolledCount ?? 0,
      );
    }

    return DashboardSessionResult(
      current: wrap(current),
      next: wrap(next),
      past: wrap(mostRecentPast),
    );
  }

  static List<List<String>> _chunk(List<String> list, int size) {
    final chunks = <List<String>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }
}

class _ClassInfo {
  final String name;
  final int enrolledCount;
  _ClassInfo({required this.name, required this.enrolledCount});
}