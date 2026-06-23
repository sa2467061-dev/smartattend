import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/class_model.dart';
import '../widgets/class_card.dart';

class StudentClassScreen extends StatefulWidget {
  final VoidCallback? onProfilePressed;

  const StudentClassScreen({super.key, this.onProfilePressed});

  @override
  State<StudentClassScreen> createState() => _StudentClassScreenState();
}

class _StudentClassScreenState extends State<StudentClassScreen> {
  int _selectedJoinType = 0; 
  final TextEditingController _inputController = TextEditingController();
  bool _isJoining = false;

  // Cache user data locally to minimize frequent database fetches
  String? _myMatrixNo;

  @override
  void initState() {
    super.initState();
    _fetchStudentProfile();
  }

  // Fetch the logged-in student's matrix number from their user document
  Future<void> _fetchStudentProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _myMatrixNo = userDoc.data()?['matrix_no'];
        });
      }
    }
  }

  // Pure logic utility to extract code string from raw input strings
  String _extractCode(String input) {
    if (_selectedJoinType == 0) {
      return input.trim().toUpperCase(); // PIN Input is clean
    } else {
      // RegEx searching for exactly 6 alphanumeric characters at the end of a link query parameters
      final RegExp regExp = RegExp(r'code=([A-Z0-9]{6})', caseSensitive: false);
      final match = regExp.firstMatch(input);
      if (match != null) {
        return match.group(1)!.toUpperCase();
      }
      // Fallback: if they just pass a clean 6 digit string to the link field anyway
      return input.trim().toUpperCase();
    }
  }

  Future<void> _joinClass(StateSetter setModalState) async {
    final rawInput = _inputController.text.trim();
    if (rawInput.isEmpty || _myMatrixNo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification failed. Try again.')),
      );
      return;
    }

    final targetCode = _extractCode(rawInput);

    if (targetCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid code pattern detected. Must be 6 characters.')),
      );
      return;
    }

    setModalState(() => _isJoining = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('classes')
          .where('class_code', isEqualTo: targetCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class not found!')));
        return;
      }

      final classDoc = query.docs.first;
      final List enrolled = classDoc['enrolled_stud'] ?? [];

      if (enrolled.contains(_myMatrixNo)) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are already enrolled!')));
        return;
      }

      // Atomic Update Transaction block
      await classDoc.reference.update({
        'enrolled_stud': FieldValue.arrayUnion([_myMatrixNo]),
        'student_count': FieldValue.increment(1),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined class!'), backgroundColor: Colors.green),
        );
        _inputController.clear();
        Navigator.pop(context); // Dismiss modal sheet
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setModalState(() => _isJoining = false);
    }
  }

  void _showAddClassBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24, left: 24, right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Add New Class', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  Center(
                    child: ToggleButtons(
                      direction: Axis.horizontal,
                      onPressed: (int index) {
                        setModalState(() {
                          _selectedJoinType = index;
                          _inputController.clear();
                        });
                      },
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      selectedBorderColor: const Color(0xff004ce6),
                      selectedColor: Colors.white,
                      fillColor: const Color(0xff004ce6),
                      color: Colors.grey.shade700,
                      constraints: BoxConstraints(
                        minWidth: (MediaQuery.of(context).size.width - 64) / 2,
                        minHeight: 40.0,
                      ),
                      isSelected: [_selectedJoinType == 0, _selectedJoinType == 1],
                      children: const [
                        Text('Use PIN', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('Use Link', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  TextField(
                    controller: _inputController,
                    keyboardType: _selectedJoinType == 0 ? TextInputType.text : TextInputType.url,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: _selectedJoinType == 0 ? 'Enter Class PIN' : 'Enter Class Invite Link',
                      hintText: _selectedJoinType == 0 ? 'e.g., XF89WZ' : 'https://smartattend.com/join?code=XF89WZ',
                      prefixIcon: Icon(_selectedJoinType == 0 ? Icons.pin : Icons.link),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xff004ce6), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton(
                    onPressed: _isJoining ? null : () => _joinClass(setModalState),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff004ce6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isJoining 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Join Class', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        titleSpacing: 16,
        automaticallyImplyLeading: false,
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
      // Live Stream of enrolled courses matching this specific student profile instance array list data trace
      body: _myMatrixNo == null 
        ? const Center(child: CircularProgressIndicator(color: Color(0xff004ce6)))
        : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .where('enrolled_stud', arrayContains: _myMatrixNo)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No classes joined yet.\nTap the Add Class button to enter a course.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, height: 1.5),
                  ),
                );
              }

              final classDocs = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: classDocs.length,
                itemBuilder: (context, index) {
                  final data = classDocs[index].data() as Map<String, dynamic>;
                  final classModelInstance = ClassModel.fromFirestore(data, classDocs[index].id);

                  // Using the shared reusable generic container design architecture
                  return ClassCard(classData: classModelInstance);
                },
              );
            },
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClassBottomSheet,
        backgroundColor: const Color(0xff004ce6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Class'),
      ),
    );
  }
}