import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'class_model.dart';
import 'class_detail.dart';

class ClassCard extends StatelessWidget {
  final ClassModel classData;
  final String userRole;
  final String userId; // matrix number (student) or uid (lecturer)

  const ClassCard({
    super.key,
    required this.classData,
    required this.userRole,
    required this.userId,
  });

  // Helper method to fetch the lecturer's name using lectId
  Future<String> _getLecturerName(String lectId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(lectId)
          .get();
      if (userDoc.exists) {
        return userDoc['name'] ?? 'Unknown Lecturer';
      }
    } catch (e) {
      return 'Error loading name';
    }
    return 'Unknown Lecturer';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassDetailScreen(
                classData: classData,
                userRole: userRole,
                userId: userId, // 👈 now passed through
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff111827)),
              ),
              const SizedBox(height: 6),
              FutureBuilder<String>(
                future: _getLecturerName(classData.lectId),
                builder: (context, snapshot) {
                  String lectName = snapshot.connectionState == ConnectionState.waiting 
                      ? 'Loading lecturer...' 
                      : (snapshot.data ?? 'Unknown Lecturer');
                  
                  return Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        lectName,
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
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