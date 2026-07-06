import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single attendance document from the `attendance` collection.
///
/// Firestore shape:
/// attendance ( att_id, ses_id, cls_id, stud_id, status, timestamp, proof,
///              proof_reason, proof_status, proof_submitted_at, seen )
///
/// One doc is pre-seeded per enrolled student when a session is created
/// (status: 'pending'), then updated to 'present' or 'absent'.
///
/// `status` tracks ATTENDANCE ('pending' | 'present' | 'absent').
/// `proof_status` tracks the PROOF-OF-ABSENCE REVIEW workflow separately
/// ('pending' | 'approved' | 'rejected' | null when no proof submitted yet).
/// Keeping these two fields distinct avoids ambiguity between "attendance
/// pending" and "proof review pending".
class AttendanceModel {
  final String attId; // Firestore document ID
  final String sesId;
  final String clsId;
  final String studId; // matrix number
  final String status; // 'pending' | 'present' | 'absent'
  final DateTime? timestamp; // when the student ticked attendance (null if pending)
  final String? proof; // URL/path to uploaded proof-of-absence image, if any
  final String? proofReason; // optional text reason accompanying the proof
  final String? proofStatus; // 'pending' | 'approved' | 'rejected' | null
  final DateTime? proofSubmittedAt; // when the proof/reason was (last) submitted
  final bool seen; // whether the lecturer has viewed this submission

  AttendanceModel({
    required this.attId,
    required this.sesId,
    required this.clsId,
    required this.studId,
    required this.status,
    this.timestamp,
    this.proof,
    this.proofReason,
    this.proofStatus,
    this.proofSubmittedAt,
    this.seen = true,
  });

  bool get isPending => status == 'pending';
  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';

  bool get hasProof => proof != null && proof!.isNotEmpty;
  bool get hasProofReason => proofReason != null && proofReason!.isNotEmpty;
  bool get hasSubmission => hasProof || hasProofReason;

  bool get proofPending => proofStatus == 'pending';
  bool get proofApproved => proofStatus == 'approved';
  bool get proofRejected => proofStatus == 'rejected';
  bool get proofNotSubmitted => proofStatus == null;

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
      proofStatus: data['proof_status'],
      proofSubmittedAt: toDateOrNull(data['proof_submitted_at']),
      seen: data['seen'] ?? true,
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
      'proof_status': proofStatus,
      'proof_submitted_at':
          proofSubmittedAt != null ? Timestamp.fromDate(proofSubmittedAt!) : null,
      'seen': seen,
    };
  }
}