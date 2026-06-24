import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'student_class.dart';
import 'student_history.dart';
import 'student_profile.dart';

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
    // 1. Establish the clean user ID chain with an active fallback
    final String? effectiveUid = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;

    // Helper function to handle passing userId straight down into the profile route context
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
        // Show a loading screen while fetching user profile details (like matrix number)
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


        // 2. Cascade down variables including the fixed matrixNo parameters
        final List<Widget> tabs = [
          StudentHomeTab(onProfilePressed: openProfile, userId: effectiveUid), 
          StudentClassScreen(onProfilePressed: openProfile, userId: effectiveUid ?? ''), // ✅ Matrix number passed safely!
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
            selectedItemColor: const Color(0xff004ce6), // Student Theme Blue
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
class StudentHomeTab extends StatelessWidget {
  final VoidCallback onProfilePressed;
  final String? userId; 

  const StudentHomeTab({
    super.key,
    required this.onProfilePressed,
    this.userId,
  });

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
              onTap: onProfilePressed, 
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xff004ce6),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: userId != null 
                  ? FirebaseFirestore.instance.collection('users').doc(userId).get()
                  : null,
              builder: (context, snapshot) {
                String greetingName = 'Student';
                
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null) {
                    greetingName = data['name'] ?? greetingName;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      greetingName,
                      style: const TextStyle(
                        fontSize: 26, 
                        fontWeight: FontWeight.bold, 
                        color: Color(0xff111827),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            _buildSessionPlaceholder('Current Session', Icons.play_circle_outline),
            const SizedBox(height: 12),
            _buildSessionPlaceholder('Next Session', Icons.update),
            const SizedBox(height: 12),
            _buildSessionPlaceholder('Past Session', Icons.history),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionPlaceholder(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade500.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 22),
          const SizedBox(width: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}