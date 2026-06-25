import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/class_model.dart'; // Verify this path matches your project structure
import '../lecturer/add_session.dart'; // Ensure this path is correct for your project
import '../session/session_model.dart'; // Adjust path to match your project structure
import '../session/current_session_card.dart';
import '../session/next_session_card.dart';
import '../session/past_session_card.dart';

class ClassDetailScreen extends StatelessWidget {
  final ClassModel classData;
  final String userRole;
  final String userId; // matrix number (student) or uid (lecturer)

  const ClassDetailScreen({
    super.key,
    required this.classData,
    required this.userRole,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLecturer = userRole == 'lecturer';

    // Lecturers get a clean tab system; students get a direct overview list
    return DefaultTabController(
      length: isLecturer ? 2 : 1,
      child: Scaffold(
        backgroundColor: const Color(0xfff8f9fa),
        appBar: AppBar(
          title: Text(classData.name),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
          bottom: TabBar(
            labelColor: const Color(0xff004ce6),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xff004ce6),
            tabs: [
              const Tab(text: 'Sessions'),
              if (isLecturer) const Tab(text: 'Students Enrolled'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Class Sessions (Shared Layout view)
            _SessionsTab(classData: classData, isLecturer: isLecturer, userId: userId),

            // Tab 2: Student Management List (Lecturer Only View)
            if (isLecturer) _StudentsListTab(classData: classData),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 1. SESSIONS VIEW TAB (Shared by both)
// ==========================================
class _SessionsTab extends StatelessWidget {
  final ClassModel classData;
  final bool isLecturer;
  final String userId;

  const _SessionsTab({required this.classData, required this.isLecturer, required this.userId});

  void _openAddSessionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSessionSheet(classId: classData.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        // Top info displaying code & stats
        _buildHeaderCard(classData),
        const SizedBox(height: 24),

        // Action Floating Row Context
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Sessions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff111827)),
            ),
            if (isLecturer)
              ElevatedButton.icon(
                onPressed: () => _openAddSessionSheet(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff004ce6)),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text('New Session', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        const SizedBox(height: 16),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('session')
              .where('cls_id', isEqualTo: classData.id)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(child: CircularProgressIndicator(color: Color(0xff004ce6))),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text('Failed to load sessions: ${snapshot.error}', style: const TextStyle(color: Colors.grey)),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Text('No active classroom tracking sequences running yet.', style: TextStyle(color: Colors.grey)),
                ),
              );
            }

            final sessions = docs.map(SessionModel.fromFirestore).toList();
            final now = DateTime.now();

            // Sort: current first, then soonest-upcoming, then most-recent-past last.
            sessions.sort((a, b) {
              int rank(SessionModel s) {
                if (s.isCurrent(now: now)) return 0;
                if (s.isUpcoming(now: now)) return 1;
                return 2;
              }
              final rankA = rank(a);
              final rankB = rank(b);
              if (rankA != rankB) return rankA.compareTo(rankB);

              // Within the same rank: upcoming sorts soonest-first,
              // past sorts most-recent-first, current order doesn't matter much.
              if (rankA == 1) return a.startTime.compareTo(b.startTime);
              if (rankA == 2) return b.endTime.compareTo(a.endTime);
              return 0;
            });

            return Column(
              children: sessions.map((session) {
                Widget card;
                if (session.isCurrent(now: now)) {
                  card = CurrentSessionCard(
                    session: session,
                    className: classData.name,
                    userId: userId,
                    userRole: isLecturer ? 'lecturer' : 'student',
                  );
                } else if (session.isUpcoming(now: now)) {
                  card = NextSessionCard(
                    session: session,
                    className: classData.name,
                    userId: userId,
                    userRole: isLecturer ? 'lecturer' : 'student',
                  );
                } else {
                  card = PastSessionCard(
                    session: session,
                    className: classData.name,
                    userId: userId,
                    userRole: isLecturer ? 'lecturer' : 'student',
                    totalEnrolled: classData.enrolledStud.length,
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: card,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeaderCard(ClassModel classData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Class Join Code:', style: TextStyle(fontWeight: FontWeight.w500)),
              Text(classData.classCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff004ce6))),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Students Enrolled:'),
              Text('${classData.enrolledStud.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. STUDENT LIST TAB (Lecturer View Only)
// ==========================================
class _StudentsListTab extends StatelessWidget {
  final ClassModel classData;

  const _StudentsListTab({required this.classData});

  @override
  Widget build(BuildContext context) {
    if (classData.enrolledStud.isEmpty) {
      return const Center(child: Text('No students have enrolled yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24.0),
      itemCount: classData.enrolledStud.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final studentMatrix = classData.enrolledStud[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text('Student Matrix: $studentMatrix'),
          subtitle: const Text('Status: Enrolled via application entry'),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        );
      },
    );
  }
}