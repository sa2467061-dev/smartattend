import 'package:flutter/material.dart';
import '../lecturer/lecturer_class.dart';
import '../lecturer/lecturer_history.dart';
import '../lecturer/lecturer_profile.dart';

class LecturerDashboard extends StatefulWidget {
  const LecturerDashboard({super.key});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Helper function to handle opening the Lecturer Profile Screen
    void _openProfile() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LecturerProfileScreen()),
      );
    }

    // Tabs configuration containing Home, Classes, and History
    final List<Widget> _tabs = [
      LecturerHomeTab(onProfilePressed: _openProfile),
      LecturerClassScreen(onProfilePressed: _openProfile),   // Pass to top bar action
      LecturerHistoryScreen(onProfilePressed: _openProfile), // Pass to top bar action
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xff111827), // Dark grey theme for lecturers
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
  }
}

// Lecturer Main Home View Tab
class LecturerHomeTab extends StatelessWidget {
  final VoidCallback onProfilePressed;

  const LecturerHomeTab({
    super.key,
    required this.onProfilePressed,
  });

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
            Icon(Icons.domain_verification, color: Color(0xff111827), size: 28),
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
              onTap: onProfilePressed, // Navigates to profile screen view
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xff111827),
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
              const Text(
                'Welcome Back, Lecturer',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff1f2937)),
              ),
              const Text(
                'Manage your classes and verify student attendance targets.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildMenuCard(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Generate Attendance QR',
                      description: 'Create a new geofenced session code.',
                      color: const Color(0xff004ce6),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuCard(
                      icon: Icons.assignment_turned_in_outlined,
                      title: 'View Active Sessions',
                      description: 'Track incoming student check-ins live.',
                      color: const Color(0xff10b981),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'Attendance Analytics',
                      description: 'Export statistical course summaries.',
                      color: const Color(0xfff59e0b),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(description, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}