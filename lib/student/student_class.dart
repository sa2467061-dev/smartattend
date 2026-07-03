import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/class_card.dart';
import '../widgets/class_model.dart';

class StudentClassScreen extends StatefulWidget {
  final VoidCallback onProfilePressed;
  final String
      userId; // Made required since we must have it to fetch profile data

  const StudentClassScreen({
    super.key,
    required this.onProfilePressed,
    required this.userId, // Pass this from dashboard
  });

  @override
  State<StudentClassScreen> createState() => _StudentClassScreenState();
}

class _StudentClassScreenState extends State<StudentClassScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isJoining = false;
  String?
      _fetchedMatrixNo; // Cache the matrix number once loaded (used for display/stream only)

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // Handles linking a student to a class via its unique room code
  Future<void> _joinClassByCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid class code.')),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      // DEBUG: confirm exactly which document we're reading
      debugPrint('[JOIN] widget.userId = "${widget.userId}"');

      // Fetch matrix number directly, instead of relying on cached state
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      // DEBUG: confirm the doc exists and dump its raw data
      debugPrint('[JOIN] userDoc.exists = ${userDoc.exists}');
      debugPrint('[JOIN] userDoc.data() = ${userDoc.data()}');

      if (!userDoc.exists) {
        throw 'No user profile found for this account (userId: ${widget.userId}). '
            'Check that the Firestore "users" document ID matches the Auth UID.';
      }

      final userData = userDoc.data();
      final String studentMatrixNo =
          (userData?['matrix_no'] ?? '').toString().trim();

      debugPrint('[JOIN] studentMatrixNo = "$studentMatrixNo"');

      if (studentMatrixNo.isEmpty) {
        throw 'Your profile is missing a matrix number. '
            'Check the "matrix_no" field on document users/${widget.userId} in Firestore.';
      }

      final classQuery = await FirebaseFirestore.instance
          .collection('classes')
          .where('class_code', isEqualTo: code)
          .limit(1)
          .get();

      if (!mounted) return;

      if (classQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Class code not found. Check with your lecturer.')),
        );
        setState(() => _isJoining = false);
        return;
      }

      final classDoc = classQuery.docs.first;

      await classDoc.reference.update({
        'enrolled_stud': FieldValue.arrayUnion([studentMatrixNo]),
      });

      if (!mounted) return;

      setState(() => _isJoining = false);
      _codeController.clear();
      Navigator.pop(context); // Dismiss the modal sheet overlay

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Successfully joined ${classDoc.get('name') ?? 'Class'}!')),
      );
    } catch (e) {
      debugPrint('[JOIN] ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join class: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  // Displays input pane to capture alphanumeric course codes safely
  void _showJoinClassDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.bottomSheetTheme.backgroundColor ??
          theme.scaffoldBackgroundColor,
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
                Text(
                  'Join Class',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ask your lecturer for the class code to add it to your profile dashboard list.',
                  style: TextStyle(
                      color: colorScheme.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _codeController,
                  enabled: !_isJoining,
                  decoration: InputDecoration(
                    hintText: 'e.g. ITS652',
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
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _isJoining
                        ? null
                        : () async {
                            await _joinClassByCode();
                          },
                    child: _isJoining
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: colorScheme.onPrimary, strokeWidth: 2),
                          )
                        : Text('Add Class',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary)),
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
            Text(
              'SMARTATTEND',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 0.5,
                  color: colorScheme.onSurface),
            ),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Enrolled Classes',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline,
                        color: colorScheme.primary, size: 28),
                    onPressed: _showJoinClassDialog,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'View active tracks and your geofenced enrollment codes.',
                style: TextStyle(
                    color: colorScheme.onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Expanded(
                // 1. First fetch the student's personal info to grab their matrix number
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.userId)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (userSnapshot.hasError ||
                        !userSnapshot.hasData ||
                        !userSnapshot.data!.exists) {
                      // DEBUG: this fires if the doc ID (widget.userId) doesn't exist in 'users'
                      debugPrint(
                          '[BUILD] No user doc found for userId="${widget.userId}"');
                      return Center(
                        child: Text(
                          'Failed to load user profile.\n(userId: ${widget.userId})',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>?;
                    debugPrint('[BUILD] userData = $userData');

                    _fetchedMatrixNo =
                        (userData?['matrix_no'] ?? '').toString().trim();

                    if (_fetchedMatrixNo!.isEmpty) {
                      return Center(
                        child: Text(
                          'Matrix number not found in profile.\n(userId: ${widget.userId})',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    // 2. Once we have the matrix number, look up the classes they belong to
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('classes')
                          .where('enrolled_stud',
                              arrayContains: _fetchedMatrixNo)
                          .snapshots(),
                      builder: (context, classSnapshot) {
                        if (classSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!classSnapshot.hasData ||
                            classSnapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.class_outlined,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'No enrolled classes yet.',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: classSnapshot.data!.docs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final doc = classSnapshot.data!.docs[index];
                            final classModel = ClassModel.fromFirestore(doc);
                            return ClassCard(
                              classData: classModel,
                              userRole: 'student',
                              userId: _fetchedMatrixNo ?? '',
                            );
                          },
                        );
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
}
