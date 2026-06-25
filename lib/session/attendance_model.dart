import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single attendance document from the `attendance` collection.
///
/// Firestore shape:
/// attendance ( att_id, ses_id, cls_id, stud_id, status, timestamp, proof )
///
/// One doc is pre-seeded per enrolled student when a session is created
/// (status: 'pending'), then updated to 'present' or 'absent'.
class AttendanceModel {
  final String attId; // Firestore document ID
  final String sesId;
  final String clsId;
  final String studId; // matrix number
  final String status; // 'pending' | 'present' | 'absent'
  final DateTime? timestamp; // when the student ticked attendance (null if pending)
  final String? proof; // URL/path to uploaded proof-of-absence image, if any
  final String? proofReason; // optional text reason accompanying the proof

  AttendanceModel({
    required this.attId,
    required this.sesId,
    required this.clsId,
    required this.studId,
    required this.status,
    this.timestamp,
    this.proof,
    this.proofReason,
  });

  bool get isPending => status == 'pending';
  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? toDateOrNull(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return AttendanceModel(
      attId: doc.id,
      sesId: data['ses_id'] ?? '',
      clsId: data['cls_id'] ?? '',
      studId: data['stud_id'] ?? '',
      status: data['status'] ?? 'pending',
      timestamp: toDateOrNull(data['timestamp']),
      proof: data['proof'],
      proofReason: data['proof_reason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ses_id': sesId,
      'cls_id': clsId,
      'stud_id': studId,
      'status': status,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
      'proof': proof,
      'proof_reason': proofReason,
    };
  }
}