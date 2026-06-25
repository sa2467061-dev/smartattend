import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../session/session_model.dart'; // adjust import path to match your project structure

/// Compact card for the dashboard's "Next Session" slot.
/// Shows class name, time, and location. Students additionally see a
/// "Send Proof of Absence" action that opens an inline dialog to upload
/// an image and a short reason, written to their attendance doc for
/// this upcoming session.
class NextSessionCard extends StatelessWidget {
  final SessionModel session;
  final String className;
  final String userId; // matrix number, used to locate the student's attendance doc
  final String userRole; // 'student' | 'lecturer'

  const NextSessionCard({
    super.key,
    required this.session,
    required this.className,
    required this.userId,
    required this.userRole,
  });

  void _openProofDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ProofOfAbsenceDialog(
        sesId: session.sesId,
        clsId: session.clsId,
        studId: userId,
      ),
    );
  }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.update, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'NEXT SESSION',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            className,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff111827)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.schedule, size: 15, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                '${_formatDate(session.startTime)} \u2022 ${_formatTime(session.startTime)} - ${_formatTime(session.endTime)}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 15, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  session.locationName,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (userRole == 'student') ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openProofDialog(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xff004ce6),
                  side: const BorderSide(color: Color(0xff004ce6)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.upload_file_rounded, size: 16),
                label: const Text('Send Proof of Absence', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
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
}

// ==========================================
// Proof of Absence Dialog
// ==========================================
class _ProofOfAbsenceDialog extends StatefulWidget {
  final String sesId;
  final String clsId;
  final String studId;

  const _ProofOfAbsenceDialog({
    required this.sesId,
    required this.clsId,
    required this.studId,
  });

  @override
  State<_ProofOfAbsenceDialog> createState() => _ProofOfAbsenceDialogState();
}

class _ProofOfAbsenceDialogState extends State<_ProofOfAbsenceDialog> {
  final TextEditingController _reasonController = TextEditingController();
  File? _selectedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();

    if (_selectedImage == null && reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach proof or write a reason.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? proofUrl;

      // 1. Upload image to Firebase Storage, if provided
      if (_selectedImage != null) {
        final fileName = 'proof_${widget.sesId}_${widget.studId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child('proof_of_absence/$fileName');
        await ref.putFile(_selectedImage!);
        proofUrl = await ref.getDownloadURL();
      }

      // 2. Find this student's attendance doc for this session
      final attendanceQuery = await FirebaseFirestore.instance
          .collection('attendance')
          .where('ses_id', isEqualTo: widget.sesId)
          .where('stud_id', isEqualTo: widget.studId)
          .limit(1)
          .get();

      if (attendanceQuery.docs.isEmpty) {
        throw 'Attendance record not found for this session.';
      }

      // 3. Update the doc with proof info. Status stays as-is (pending/absent) —
      // the lecturer reviews proof separately rather than auto-approving here.
      await attendanceQuery.docs.first.reference.update({
        'proof': proofUrl,
        'proof_reason': reason,
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proof of absence submitted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send Proof of Absence',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xff111827)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Attach supporting evidence (e.g. medical certificate) and/or a brief reason.',
              style: TextStyle(color: Colors.grey, fontSize: 12.5),
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: _isSubmitting ? null : _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xfff8f9fa),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, color: Colors.grey.shade500, size: 28),
                          const SizedBox(height: 6),
                          Text('Tap to attach image', style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
                      ),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _reasonController,
              enabled: !_isSubmitting,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Medical appointment, family emergency...',
                filled: true,
                fillColor: const Color(0xfff8f9fa),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff004ce6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}