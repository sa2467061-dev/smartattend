import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String id;
  final String name;
  final String lectId;
  final String classCode;
  final int studentCount;
  final List<String> enrolledStud;

  ClassModel({
    required this.id,
    required this.name,
    required this.lectId,
    required this.classCode,
    required this.studentCount,
    required this.enrolledStud,
  });

  // A single, complete factory constructor that reads directly from a Firestore Document
  factory ClassModel.fromFirestore(DocumentSnapshot doc) {
    // Safely cast the document data to a Map
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

    return ClassModel(
      id: doc.id,
      name: data['name'] ?? 'Unknown Class',
      lectId: data['lect_id'] ?? '',
      classCode: data['class_code'] ?? 'N/A',
      studentCount: data['student_count'] ?? 0,
      enrolledStud: List<String>.from(data['enrolled_stud'] ?? []),
    );
  }
}