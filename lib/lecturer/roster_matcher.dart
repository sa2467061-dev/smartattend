import 'package:cloud_firestore/cloud_firestore.dart';

class RosterMatchResult {
  final List<String> matched; // matrix numbers found in users collection
  final List<String> unmatched; // matrix numbers NOT found

  RosterMatchResult({required this.matched, required this.unmatched});
}

/// Checks a list of extracted matrix numbers against the `users` collection
/// (role: student) and reports which ones correspond to real registered
/// students. Does not write anything — pure lookup.
class RosterMatcher {
  static Future<RosterMatchResult> matchAgainstStudents(
      List<String> candidateMatrixNumbers) async {
    if (candidateMatrixNumbers.isEmpty) {
      return RosterMatchResult(matched: [], unmatched: []);
    }

    final Set<String> matched = {};

    // Firestore whereIn supports up to 30 items per query.
    for (int i = 0; i < candidateMatrixNumbers.length; i += 30) {
      final chunk = candidateMatrixNumbers.sublist(
        i,
        i + 30 > candidateMatrixNumbers.length ? candidateMatrixNumbers.length : i + 30,
      );

      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('matrix_no', whereIn: chunk)
          .get();

      for (final doc in snap.docs) {
        final matrixNo = doc.data()['matrix_no'];
        if (matrixNo != null) matched.add(matrixNo.toString().toUpperCase());
      }
    }

    final unmatched = candidateMatrixNumbers.where((m) => !matched.contains(m)).toList();

    return RosterMatchResult(matched: matched.toList(), unmatched: unmatched);
  }
}