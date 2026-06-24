import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/class_card.dart';
import '../widgets/class_model.dart';


class StudentClassScreen extends StatefulWidget {
  final VoidCallback onProfilePressed;
  final String? userId;

  const StudentClassScreen({
    super.key,
    required this.onProfilePressed,
    this.userId,
  });

  @override
  State<StudentClassScreen> createState() => _StudentClassScreenState();
}

class _StudentClassScreenState extends State<StudentClassScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // Logic block to handle linking a student to a class via its distinct code
  Future<void> _joinClassByCode() async {
    if (widget.userId == null) return;
    
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid class code.')),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      // Find the class document matching the provided class code
      final classQuery = await FirebaseFirestore.instance
          .collection('classes')
          .where('class_code', isEqualTo: code)
          .limit(1)
          .get();

      if (!mounted) return;

      if (classQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class code not found. Check with your lecturer.')),
        );
        setState(() => _isJoining = false);
        return;
      }

      final classDoc = classQuery.docs.first;

     // Fetch the student's matrix number from their user document first
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(widget.userId) // Their Firebase Auth UID
    .get();

if (!userDoc.exists) {
  throw 'User document profile not found.';
}

final String studentMatrixNo = userDoc.get('matrix_no') ?? '';
if (studentMatrixNo.isEmpty) {
  throw 'Your profile is missing a matrix number.';
}

// Then update the array using the matrix number instead of the UID
await classDoc.reference.update({
  'enrolled_stud': FieldValue.arrayUnion([studentMatrixNo]),
});

      if (!mounted) return;
      
      // Cleanly flip the state back before popping the modal overlay sheet
      setState(() => _isJoining = false);
      _codeController.clear();
      
      Navigator.pop(context); // Dismiss the sheet dialog block
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully joined ${classDoc.get('name') ?? 'Class'}!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join class: $e')),
      );
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  // Pop up an entry panel dialog to capture user input safely
  void _showJoinClassDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Join Class',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff111827)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ask your lecturer for the class code to add it to your profile dashboard list.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _codeController,
                  enabled: !_isJoining, // Disables text field while server call processing executes
                  decoration: InputDecoration(
                    hintText: 'e.g. ITS652',
                    filled: true,
                    fillColor: _isJoining ? const Color(0xffe9ecef) : const Color(0xfff8f9fa),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff004ce6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _isJoining ? null : () async {
                      // Uses sequential evaluation to match outer context handling
                      await _joinClassByCode();
                    },
                    child: _isJoining
                        ? const SizedBox(
                            height: 20, 
                            width: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Add Class', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
            Icon(Icons.domain_verification, color: Color(0xff004ce6), size: 28),
            SizedBox(width: 8),
            Text(
              'SMARTATTEND',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: widget.onProfilePressed,
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xff004ce6),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Enrolled Classes',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xff111827)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Color(0xff004ce6), size: 28),
                    onPressed: _showJoinClassDialog,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'View active tracks and your geofenced enrollment codes.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              
              Expanded(
                child: widget.userId == null
                    ? const Center(child: Text('User not verified.'))
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('classes')
                            .where('enrolled_stud', arrayContains: widget.userId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.class_outlined, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No enrolled classes yet.',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                                  ),
                                ],
                              ),
                            );
                          }

                         return ListView.separated(
  itemCount: snapshot.data!.docs.length,
  separatorBuilder: (context, index) => const SizedBox(height: 14),
  itemBuilder: (context, index) {
    final doc = snapshot.data!.docs[index];
    
    // 1. Convert the Firestore document snapshot safely into your new ClassModel
    final classModel = ClassModel.fromFirestore(doc);

    // 2. Return your dedicated ClassCard component and pass the model data into it
    return ClassCard(classData: classModel);
  },
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

  Widget _buildClassCard({
    required String className,
    required String classCode,
    required String lecturerName,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classCode,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xff004ce6)),
                ),
                const SizedBox(height: 2),
                Text(
                  className,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff111827)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(lecturerName, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}