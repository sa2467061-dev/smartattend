import 'package:flutter/material.dart';
import '../widgets/class_model.dart';

class ClassDetailScreen extends StatelessWidget {
  final ClassModel classData;
  final String userRole; // Add this line to accept 'lecturer' or 'student'

  const ClassDetailScreen({
    super.key, 
    required this.classData, 
    required this.userRole, // Mark it required
  });

  @override
  Widget build(BuildContext context) {
    // Check role boolean states for cleaner code readability
    final bool isLecturer = userRole == 'lecturer';

    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        title: Text(classData.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Course Title ---
            Text(
              classData.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xff111827)),
            ),
            const SizedBox(height: 16),

            // --- Shared Info Card ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Class Join Code:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(classData.classCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Students Enrolled:'),
                      Text('${classData.studentCount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- CONDITIONAL INTERFACE LAYOUT ---
            if (isLecturer) ...[
              // Actions ONLY the Lecturer can see
              const Text('Lecturer Tools', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff111827),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () { /* Excel upload logic */ },
                icon: const Icon(Icons.upload_file, color: Colors.white),
                label: const Text('Import Student Excel List', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () { /* Create session logic */ },
                icon: const Icon(Icons.add_location_alt, color: Colors.white),
                label: const Text('Create Attendance Session', style: TextStyle(color: Colors.white)),
              ),
            ] else ...[
              // Actions ONLY the Student can see
              const Text('Student Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff111827),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () { /* QR scanning view flow */ },
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                label: const Text('Scan QR Attendance', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xff111827)),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () { /* View attendance logs */ },
                icon: const Icon(Icons.history, color: Color(0xff111827)),
                label: const Text('View My Attendance History', style: TextStyle(color: Color(0xff111827))),
              ),
            ],
          ],
        ),
      ),
    );
  }
}