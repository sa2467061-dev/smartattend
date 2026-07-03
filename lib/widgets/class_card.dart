import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'class_model.dart';
import 'class_detail.dart';

class ClassCard extends StatelessWidget {
  final ClassModel classData;
  final String userRole;
  final String userId;

  const ClassCard({
    super.key,
    required this.classData,
    required this.userRole,
    required this.userId,
  });

  Future<String> _getLecturerName(String lectId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(lectId)
          .get();
      if (doc.exists) return doc['name'] ?? 'Unknown Lecturer';
    } catch (_) {}
    return 'Unknown Lecturer';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassDetailScreen(
                classData: classData,
                userRole: userRole,
                userId: userId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                classData.name,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface),
              ),
              const SizedBox(height: 6),
              FutureBuilder<String>(
                future: _getLecturerName(classData.lectId),
                builder: (context, snapshot) {
                  final lectName =
                      snapshot.connectionState == ConnectionState.waiting
                          ? 'Loading lecturer...'
                          : (snapshot.data ?? 'Unknown Lecturer');
                  return Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(lectName,
                          style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 14)),
                    ],
                  );
                },
              ),

              // ── Lecturer-only: Students Enrolled button ──────────────────
              if (userRole == 'lecturer') ...[
                const SizedBox(height: 12),
                Divider(height: 1, color: theme.dividerColor),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.group_outlined,
                        size: 15, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      '${classData.enrolledStud.length} student${classData.enrolledStud.length == 1 ? '' : 's'} enrolled',
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _EnrolledStudentsScreen(
                            classId: classData.id,
                            className: classData.name,
                            enrolledMatrixNos: classData.enrolledStud,
                          ),
                        ),
                      ),
                      child: Material(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('View Students',
                                  style: TextStyle(
                                      color: theme.colorScheme.onPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded,
                                  size: 11, color: theme.colorScheme.onPrimary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Enrolled Students Screen ──────────────────────────────────────────────────
class _EnrolledStudentsScreen extends StatelessWidget {
  final String classId;
  final String className;
  final List<String> enrolledMatrixNos;

  const _EnrolledStudentsScreen({
    required this.classId,
    required this.className,
    required this.enrolledMatrixNos,
  });

  // Watch the class doc so list updates in real-time after removals
  Stream<List<Map<String, dynamic>>> _watchStudents() {
    return FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .snapshots()
        .asyncMap((classDoc) async {
      if (!classDoc.exists) return [];

      final data = classDoc.data() as Map<String, dynamic>? ?? {};
      final List<String> matrixNos =
          List<String>.from(data['enrolled_stud'] ?? []);

      if (matrixNos.isEmpty) return [];

      final List<Map<String, dynamic>> students = [];

      for (final matrixNo in matrixNos) {
        String name = matrixNo;
        String email = '';

        try {
          final userSnap = await FirebaseFirestore.instance
              .collection('users')
              .where('matrix_no', isEqualTo: matrixNo)
              .limit(1)
              .get();
          if (userSnap.docs.isNotEmpty) {
            final d = userSnap.docs.first.data();
            name = d['name'] ?? matrixNo;
            email = d['email'] ?? '';
          }
        } catch (_) {}

        students.add({
          'matrixNo': matrixNo,
          'name': name,
          'email': email,
        });
      }

      students
          .sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));

      return students;
    });
  }

  Future<void> _removeStudent(
      BuildContext context, String matrixNo, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Remove Student',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text(
            'Remove $name ($matrixNo) from $className? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffdc2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .update({
        'enrolled_stud': FieldValue.arrayRemove([matrixNo]),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name removed from $className.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove student: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Students Enrolled',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(className,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _watchStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data ?? [];

          if (students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off_outlined,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('No students enrolled yet.',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header count
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xff111827).withAlpha(8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.group_outlined,
                        size: 18, color: Color(0xff111827)),
                    const SizedBox(width: 8),
                    Text(
                      '${students.length} student${students.length == 1 ? '' : 's'} enrolled',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xff111827)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Student tiles
              ...students.asMap().entries.map((entry) {
                final index = entry.key;
                final s = entry.value;
                return _buildStudentTile(context, s, index + 1);
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStudentTile(
      BuildContext context, Map<String, dynamic> s, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: const Color(0xff111827).withAlpha(12),
          child: Text(
            '$index',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xff111827)),
          ),
        ),
        title: Text(
          s['name'],
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xff111827)),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.badge_outlined, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text(s['matrixNo'],
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ]),
            if (s['email'].toString().isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.mail_outline, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(s['email'],
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ]),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.person_remove_outlined,
              color: Color(0xffdc2626), size: 22),
          tooltip: 'Remove student',
          onPressed: () => _removeStudent(context, s['matrixNo'], s['name']),
        ),
      ),
    );
  }
}
