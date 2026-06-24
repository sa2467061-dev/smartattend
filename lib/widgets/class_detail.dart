import 'package:flutter/material.dart';
import '../widgets/class_model.dart'; // Verify this path matches your project structure
import '../lecturer/add_session.dart'; // Ensure this path is correct for your project

class ClassDetailScreen extends StatelessWidget {
  final ClassModel classData;
  final String userRole;

  const ClassDetailScreen({
    super.key, 
    required this.classData, 
    required this.userRole,
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
            _SessionsTab(classData: classData, isLecturer: isLecturer),
            
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

  const _SessionsTab({required this.classData, required this.isLecturer});

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
                onPressed: () {
                  showModalBottomSheet(
                   context: context,
                    isScrollControlled: true,
                   backgroundColor: Colors.transparent,
                   builder: (context) => AddSessionSheet(classId: classData.id),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff004ce6)),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text('New Session', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // --- TODO: Drop a StreamBuilder<QuerySnapshot> here to fetch 'sessions' sub-collection ---
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Text('No active classroom tracking sequences running yet.', style: TextStyle(color: Colors.grey)),
          ),
        )
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