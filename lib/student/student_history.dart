import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../session/attendance_model.dart';
import '../session/supabase_proof_upload.dart'; // adjust path if your folder layout differs

class StudentHistoryScreen extends StatefulWidget {
  final VoidCallback? onProfilePressed;
  final String? userId; // matrix_no

  const StudentHistoryScreen({super.key, this.onProfilePressed, this.userId});

  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  String _filter = 'All';

  Stream<Map<String, dynamic>> _watchHistoryData() {
    if (widget.userId == null) {
      return Stream.value(
          {'records': [], 'present': 0, 'absent': 0, 'rate': 0});
    }

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
              final end = (slot['end'] as Timestamp).toDate();
              endTime = end;
              isPastSession = DateTime.now().isAfter(end);
            }
          }
        } catch (_) {}

        // Show ALL sessions (ongoing + past)

        try {
          final classDoc = await FirebaseFirestore.instance
              .collection('classes')
              .doc(model.clsId)
              .get();
          if (classDoc.exists) {
            className = classDoc.data()?['name'] ?? model.clsId;
          }
        } catch (_) {}

        // pending on past session = absent; pending on ongoing = still pending
        final effectiveStatus =
            (model.isPending && isPastSession) ? 'absent' : model.status;

        if (effectiveStatus == 'present') present++;
        if (effectiveStatus == 'absent') absent++;

        records.add({
          'attId': model.attId,
          'sesId': model.sesId,
          'status': effectiveStatus,
          'className': className,
          'locationName': locationName,
          'startTime': startTime,
          'endTime': endTime,
          'proof': model.proof,
          'proofReason': model.proofReason,
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

  // ── Upload reason bottom sheet ────────────────────────────────────────────
  void _showUploadReasonSheet(String attId, String sesId, String? existingProof,
      String? existingReason) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dangerColor = Colors.red.shade600;
    final TextEditingController reasonCtrl =
        TextEditingController(text: existingReason ?? '');
    File? pickedImage;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.bottomSheetTheme.backgroundColor ??
          theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          Future<void> pickImage() async {
            final picker = ImagePicker();
            final picked = await picker.pickImage(
                source: ImageSource.gallery, imageQuality: 70);
            if (picked != null) {
              setSheet(() => pickedImage = File(picked.path));
            }
          }

          Future<void> submit() async {
            if (reasonCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a reason.')),
              );
              return;
            }
            setSheet(() => isUploading = true);

            try {
              String? proofUrl = existingProof;

              if (pickedImage != null) {
                proofUrl = await uploadAbsenceProof(
                  file: pickedImage!,
                  studId: widget.userId ?? 'unknown',
                  sesId: sesId,
                );
              }

              await FirebaseFirestore.instance
                  .collection('attendance')
                  .doc(attId)
                  .update({
                'proof': proofUrl,
                'proof_reason': reasonCtrl.text.trim(),
              });

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content: Text('Reason submitted successfully.')),
                );
              }
            } catch (e) {
              setSheet(() => isUploading = false);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Failed to submit: $e')),
                );
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: dangerColor),
                    const SizedBox(width: 8),
                    Text(
                      'Submit Absence Reason',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Provide a reason and optionally upload supporting proof (e.g. MC, university letter).',
                  style: TextStyle(
                      fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),

                // Text reason
                TextField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'e.g. Medical Certificate — fever and flu',
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Image picker
                GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    width: double.infinity,
                    height: pickedImage != null ? 160 : 80,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: colorScheme.outline, style: BorderStyle.solid),
                    ),
                    child: pickedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(pickedImage!, fit: BoxFit.cover),
                          )
                        : existingProof != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(existingProof,
                                    fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.upload_file_rounded,
                                      color: colorScheme.onSurfaceVariant,
                                      size: 28),
                                  const SizedBox(height: 6),
                                  Text('Tap to upload proof image (optional)',
                                      style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 13)),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dangerColor,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: isUploading ? null : submit,
                    child: isUploading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: colorScheme.onPrimary, strokeWidth: 2))
                        : Text(
                            existingProof != null || existingReason != null
                                ? 'Update Reason'
                                : 'Submit Reason',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary),
                          ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
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
        automaticallyImplyLeading: false,
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
              onTap: widget.onProfilePressed,
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
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _watchHistoryData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load history.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant)),
            );
          }
          final data = snapshot.data ??
              {'records': [], 'present': 0, 'absent': 0, 'rate': 0};
          final allRecords = data['records'] as List<Map<String, dynamic>>;
          final present = data['present'] as int;
          final absent = data['absent'] as int;
          final rate = data['rate'] as int;

          final filtered = _filter == 'Absent'
              ? allRecords.where((r) => r['status'] == 'absent')
              : allRecords;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Attendance History',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface)),
              const SizedBox(height: 16),
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
              Container(
                decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.all(4),
                child: Row(children: [
                  _buildFilterTab('All', allRecords.length),
                  _buildFilterTab('Absent', absent),
                ]),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      _filter == 'Absent'
                          ? 'No absent records. Great attendance!'
                          : 'No attendance records yet.',
                      style: TextStyle(
                          color: colorScheme.onSurfaceVariant, fontSize: 14),
                    ),
                  ),
                )
              else
                ...filtered.map((r) => _buildRecordCard(r)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterTab(String label, int count) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _filter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: colorScheme.onSurface.withValues(alpha: 20),
                        blurRadius: 4,
                        offset: const Offset(0, 1))
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10)),
                child: Text('$count',
                    style: TextStyle(
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
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
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = record['status'] as String;
    final className = record['className'] as String;
    final locationName = record['locationName'] as String;
    final startTime = record['startTime'] as DateTime?;
    final endTime = record['endTime'] as DateTime?;
    final attId = record['attId'] as String;
    final sesId = record['sesId'] as String;
    final proof = record['proof'] as String?;
    final proofReason = record['proofReason'] as String?;

    final isPresent = status == 'present';
    final isAbsent = status == 'absent';

    final Color barColor = isPresent
        ? const Color(0xff16a34a)
        : isAbsent
            ? const Color(0xffdc2626)
            : colorScheme.onSurfaceVariant;

    final String statusLabel = isPresent
        ? 'Present'
        : isAbsent
            ? 'Absent'
            : 'Pending';

    final String? proofReasonValue = proofReason;
    final bool hasReason =
        proofReasonValue != null && proofReasonValue.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Left color bar
              Container(
                width: 5,
                height: 80,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: barColor, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(className,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: colorScheme.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      if (startTime != null)
                        Text(_formatDate(startTime),
                            style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant)),
                      if (startTime != null && endTime != null)
                        Text(
                          '${_formatTime(startTime)} – ${_formatTime(endTime)}'
                          '${locationName.isNotEmpty ? ' · $locationName' : ''}',
                          style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: barColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(statusLabel,
                      style: TextStyle(
                          color: barColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),

          // ── Absent reason section ─────────────────────────────────────────
          if (isAbsent) ...[
            Divider(height: 1, color: colorScheme.outline),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasReason) ...[
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 14, color: const Color(0xff16a34a)),
                        const SizedBox(width: 6),
                        Text('Reason submitted',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xff16a34a),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(proofReasonValue,
                        style: TextStyle(
                            fontSize: 12, color: colorScheme.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => _showUploadReasonSheet(
                          attId, sesId, proof, proofReason),
                      icon: Icon(
                          hasReason
                              ? Icons.edit_outlined
                              : Icons.upload_file_rounded,
                          size: 16),
                      label: Text(
                        hasReason ? 'Update Reason' : 'Submit Absence Reason',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
