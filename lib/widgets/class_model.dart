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

  factory ClassModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return ClassModel(
      id: documentId,
      name: data['name'] ?? '',
      lectId: data['lect_id'] ?? '',
      classCode: data['class_code'] ?? '',
      studentCount: data['student_count'] ?? 0,
      enrolledStud: List<String>.from(data['enrolled_stud'] ?? []),
    );
  }
}