import 'package:flutter/material.dart';
import 'student_class.dart';
import 'student_history.dart';
import 'student_profile.dart';

class StudentDashboard extends StatefulWidget {
  final String? userId; // Optional parameter to pass user ID if needed
  const StudentDashboard({super.key, this.userId});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Helper function to handle opening the Profile Screen seamlessly
    void openProfile() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StudentProfileScreen()),
      );
    }

    // Only Home, Classes, and History are managed by the bottom bar tabs now
    final List<Widget> tabs = [
      StudentHomeTab(onProfilePressed: openProfile), 
      StudentClassScreen(onProfilePressed: openProfile),   // Pass to class screen top bar too
      StudentHistoryScreen(onProfilePressed: openProfile), // Pass to history screen top bar too
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
          // Profile item removed from here entirely!
        ],
      ),
    );
  }
}

// Home View Tab
class StudentHomeTab extends StatelessWidget {
  final VoidCallback onProfilePressed;

  const StudentHomeTab({
    super.key,
    required this.onProfilePressed,
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
              onTap: onProfilePressed, // Opens profile fullscreen
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
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
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}