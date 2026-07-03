import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Replaces the old "Attendance History" screen for lecturers.
/// Shows a flat, newest-first list of absence proofs/reasons submitted by
/// students across all of this lecturer's classes — skips sessions entirely.
class LecturerHistoryScreen extends StatelessWidget {
  final VoidCallback onProfilePressed;
  final String? userId; // Firebase Auth UID / Firestore lecturer doc id

  const LecturerHistoryScreen({
    super.key,
    required this.onProfilePressed,
    this.userId,
  });

  /// Exposed so the dashboard's bottom nav / app bar icon can show a red dot
  /// whenever there's at least one unseen proof, without duplicating the
  /// class-fetching logic. Usage: StreamBuilder<bool>(stream: LecturerHistoryScreen.watchHasUnseenProofs(userId), ...)
  static Stream<bool> watchHasUnseenProofs(String? userId) {
    if (userId == null) return Stream.value(false);

    return FirebaseFirestore.instance
        .collection('classes')
        .where('lect_id', isEqualTo: userId)
        .snapshots()
        .asyncMap((classSnap) async {
      if (classSnap.docs.isEmpty) return false;

      final classIds = classSnap.docs.map((d) => d.id).toList();

      for (int i = 0; i < classIds.length; i += 30) {
        final chunk = classIds.sublist(
            i, i + 30 > classIds.length ? classIds.length : i + 30);

        final attSnap = await FirebaseFirestore.instance
            .collection('attendance')
            .where('cls_id', whereIn: chunk)
            .where('seen', isEqualTo: false)
            .get();

        // Only counts toward "unseen" if it actually has a proof/reason —
        // a doc with seen:false but no proof was never a notification.
        final hasRealUnseenProof = attSnap.docs.any((doc) {
          final data = doc.data();
          final proof = data['proof'];
          final reason = data['proof_reason'];
          return (proof != null && proof.toString().isNotEmpty) ||
              (reason != null && reason.toString().isNotEmpty);
        });

        if (hasRealUnseenProof) return true;
      }

      return false;
    });
  }

  String _formatDateTime(DateTime dt) {
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
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} · $hour:$minute $period';
  }

  Stream<List<Map<String, dynamic>>> _watchProofSubmissions() {
    if (userId == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('classes')
        .where('lect_id', isEqualTo: userId)
        .snapshots()
        .asyncMap((classSnap) async {
      if (classSnap.docs.isEmpty) return [];

      final Map<String, Map<String, dynamic>> classInfo = {};
      for (final doc in classSnap.docs) {
        final d = doc.data();
        classInfo[doc.id] = {
          'name': d['name'] ?? doc.id,
          'classCode': d['class_code'] ?? '',
        };
      }

      final classIds = classInfo.keys.toList();
      final List<Map<String, dynamic>> results = [];

      for (int i = 0; i < classIds.length; i += 30) {
        final chunk = classIds.sublist(
            i, i + 30 > classIds.length ? classIds.length : i + 30);

        final attSnap = await FirebaseFirestore.instance
            .collection('attendance')
            .where('cls_id', whereIn: chunk)
            .get();

        for (final doc in attSnap.docs) {
          final data = doc.data();
          final proof = data['proof'] as String?;
          final proofReason = data['proof_reason'] as String?;

          final hasProof = proof != null && proof.isNotEmpty;
          final hasReason = proofReason != null && proofReason.isNotEmpty;
          if (!hasProof && !hasReason) continue; // skip — nothing submitted

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

          final clsId = data['cls_id'] ?? '';
          final info = classInfo[clsId] ?? {};

          DateTime? submittedAt;
          if (data['proof_submitted_at'] is Timestamp) {
            submittedAt = (data['proof_submitted_at'] as Timestamp).toDate();
          }

          results.add({
            'attId': doc.id,
            'studId': studId,
            'name': name,
            'className': info['name'] ?? clsId,
            'classCode': info['classCode'] ?? '',
            'proof': proof,
            'proofReason': proofReason,
            'seen': data['seen'] ??
                true, // docs from before this feature default to seen
            'submittedAt': submittedAt,
          });
        }
      }

      // Newest first; unseen ones with no timestamp still float near top via null-last sort
      results.sort((a, b) {
        final aT = a['submittedAt'] as DateTime?;
        final bT = b['submittedAt'] as DateTime?;
        if (aT == null && bT == null) return 0;
        if (aT == null) return 1;
        if (bT == null) return -1;
        return bT.compareTo(aT);
      });

      return results;
    });
  }

  Future<void> _markAsSeen(String attId) async {
    await FirebaseFirestore.instance
        .collection('attendance')
        .doc(attId)
        .update({'seen': true});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        foregroundColor:
            theme.appBarTheme.foregroundColor ?? colorScheme.onSurface,
        elevation: 0.5,
        titleSpacing: 16,
        title: Row(
          children: [
            Icon(Icons.domain_verification,
                color: colorScheme.primary, size: 28),
            const SizedBox(width: 8),
            Text('SMARTATTEND',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.5,
                    color: colorScheme.onSurface)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: onProfilePressed,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primary,
                child:
                    Icon(Icons.person, color: colorScheme.onPrimary, size: 20),
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
              Text('Notifications',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface)),
              const SizedBox(height: 6),
              Text(
                'Absence proofs and reasons submitted by your students.',
                style: TextStyle(
                    color: colorScheme.onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _watchProofSubmissions(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error: ${snapshot.error}',
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant)));
                    }
                    final submissions = snapshot.data ?? [];
                    if (submissions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none_rounded,
                                size: 48, color: colorScheme.onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text('No absence proofs submitted yet.',
                                style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 15)),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: submissions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _buildSubmissionCard(context, submissions[index]),
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

  Widget _buildSubmissionCard(BuildContext context, Map<String, dynamic> s) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool seen = s['seen'] as bool;
    final DateTime? submittedAt = s['submittedAt'] as DateTime?;
    final String? proof = s['proof'] as String?;
    final String? proofReason = s['proofReason'] as String?;
    final bool hasReason = proofReason != null && proofReason.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (!seen) _markAsSeen(s['attId'] as String);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _ProofDetailScreen(
              name: s['name'] as String,
              studId: s['studId'] as String,
              className: s['className'] as String,
              proof: proof,
              proofReason: proofReason,
              submittedAt: submittedAt,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seen
                ? colorScheme.outline
                : colorScheme.primary.withValues(alpha: 80),
            width: seen ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
                color: colorScheme.onSurface.withValues(alpha: 15),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unseen dot
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 10),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: seen ? Colors.transparent : colorScheme.error,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(s['name'] as String,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    seen ? FontWeight.w600 : FontWeight.bold,
                                color: colorScheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (submittedAt != null)
                        Text(_formatDateTime(submittedAt),
                            style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(s['className'] as String,
                      style: TextStyle(
                          fontSize: 12.5, color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  if (hasReason)
                    Text(proofReason!,
                        style: TextStyle(
                            fontSize: 13, color: colorScheme.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  if (proof != null && proof.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.image_outlined,
                          size: 14, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text('Proof attached',
                          style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Full detail view for a single submission ──────────────────────────────
class _ProofDetailScreen extends StatelessWidget {
  final String name;
  final String studId;
  final String className;
  final String? proof;
  final String? proofReason;
  final DateTime? submittedAt;

  const _ProofDetailScreen({
    required this.name,
    required this.studId,
    required this.className,
    required this.proof,
    required this.proofReason,
    required this.submittedAt,
  });

  String _formatDateTime(DateTime dt) {
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
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} · $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String? proofReasonValue = proofReason;
    final String? proofValue = proof;
    final DateTime? submittedAtValue = submittedAt;
    final bool hasReason =
        proofReasonValue != null && proofReasonValue.isNotEmpty;
    final bool hasProof = proofValue != null && proofValue.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        foregroundColor:
            theme.appBarTheme.foregroundColor ?? colorScheme.onSurface,
        elevation: 0.5,
        title: Text('Absence Submission',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colorScheme.onSurface)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(studId,
                    style: TextStyle(
                        fontSize: 13, color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.class_outlined,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(className,
                      style: TextStyle(
                          fontSize: 13, color: colorScheme.onSurfaceVariant)),
                ]),
                if (submittedAtValue != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.access_time_rounded,
                        size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(_formatDateTime(submittedAtValue),
                        style: TextStyle(
                            fontSize: 13, color: colorScheme.onSurfaceVariant)),
                  ]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (hasReason) ...[
            Text('Reason',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Text(proofReasonValue,
                  style: TextStyle(
                      fontSize: 14, color: colorScheme.onSurfaceVariant)),
            ),
            const SizedBox(height: 20),
          ],
          if (hasProof) ...[
            Text('Proof',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                final proofUrl = proofValue;
                _showFullImage(context, proofUrl!);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  proofValue!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: colorScheme.surfaceContainerHighest,
                    child: Center(
                        child: Text('Image unavailable',
                            style: TextStyle(
                                color: colorScheme.onSurfaceVariant))),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('Tap image to view full size',
                style: TextStyle(
                    fontSize: 11, color: colorScheme.onSurfaceVariant)),
          ],
          if (!hasReason && !hasProof)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('No content submitted.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ),
            ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: colorScheme.surface,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: CircleAvatar(
                  backgroundColor: colorScheme.onSurface.withValues(alpha: 61),
                  child: Icon(Icons.close, color: colorScheme.onSurface),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
