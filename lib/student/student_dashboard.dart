import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'student_class.dart';
import 'student_history.dart';
import 'student_profile.dart';
import '../session/session_query_helper.dart';
import '../session/current_session_card.dart';
import '../session/next_session_card.dart';
import '../session/past_session_card.dart';
  
class StudentDashboard extends StatefulWidget {
  final String? userId; 
  const StudentDashboard({super.key, this.userId});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final String? effectiveUid = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;

    void openProfile() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudentProfileScreen(userId: effectiveUid),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(effectiveUid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xff004ce6))),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Error loading user profile.')),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final String matrixNo = data?['matrix_no'] ?? '';
        final String displayName = data?['name'] ?? 'Student';

        final List<Widget> tabs = [
          StudentHomeTab(
            onProfilePressed: openProfile,
            userId: effectiveUid,
            matrixNo: matrixNo,
            displayName: displayName,
          ),
          StudentClassScreen(onProfilePressed: openProfile, userId: effectiveUid ?? ''),
          StudentHistoryScreen(onProfilePressed: openProfile, userId: effectiveUid),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: tabs,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xff004ce6),
            unselectedItemColor: Colors.grey.shade500,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.class_outlined),
                activeIcon: Icon(Icons.class_),
                label: 'Classes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_toggle_off_rounded),
                activeIcon: Icon(Icons.history_rounded),
                label: 'History',
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- Home View Tab ---
class StudentHomeTab extends StatefulWidget {
  final VoidCallback onProfilePressed;
  final String? userId;
  final String matrixNo; // needed to query session/attendance by student
  final String displayName;

  const StudentHomeTab({
    super.key,
    required this.onProfilePressed,
    this.userId,
    required this.matrixNo,
    required this.displayName,
  });

  @override
  State<StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends State<StudentHomeTab> {
  late Future<DashboardSessionResult> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    _sessionsFuture = SessionQueryHelper.fetchDashboardSessions(
      userId: widget.matrixNo,
      userRole: 'student',
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _loadSessions();
    });
    await _sessionsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                widget.displayName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff111827),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 28),

              FutureBuilder<DashboardSessionResult>(
                future: _sessionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator(color: Color(0xff004ce6))),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('Failed to load sessions: ${snapshot.error}',
                            style: const TextStyle(color: Colors.grey)),
                      ),
                    );
                  }

                  final result = snapshot.data ?? DashboardSessionResult();

                  return Column(
                    children: [
                      if (result.current != null) ...[
                        CurrentSessionCard(
                          session: result.current!.session,
                          className: result.current!.className,
                          userId: widget.matrixNo,
                          userRole: 'student',
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (result.next != null) ...[
                        NextSessionCard(
                          session: result.next!.session,
                          className: result.next!.className,
                          userId: widget.matrixNo,
                          userRole: 'student',
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (result.past != null) ...[
                        PastSessionCard(
                          session: result.past!.session,
                          className: result.past!.className,
                          userId: widget.matrixNo,
                          userRole: 'student',
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (result.current == null && result.next == null && result.past == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'No sessions to show yet.',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}