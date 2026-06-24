import 'package:flutter/material.dart';
//import '../lecturer/lecturer_profile.dart'; // Ensure correct import for profile navigation
import '../lecturer/add_class.dart';        // Imports your custom screen path
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/class_card.dart';
import '../widgets/class_model.dart';

class LecturerClassScreen extends StatelessWidget {
  final VoidCallback onProfilePressed;
  final String? userId;
  const LecturerClassScreen({
    super.key,
    required this.onProfilePressed,
    this.userId, // Optional parameter to receive user ID
  });

  @override
  Widget build(BuildContext context) {
final String? effectiveUid = userId ?? FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      // --- Consistent Top Bar Layout ---
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
              onTap: onProfilePressed, // Seamless profile access layout overlay
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xff111827),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      
      // --- Main View Content Placeholder ---
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Classes',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xff111827)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage and track your assigned courses here.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              // Replace your old Expanded block with this dynamic one:
Expanded(
  child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('classes')
        .where('lect_id', isEqualTo: effectiveUid) // Filters by logged-in lecturer
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(
          child: Text(
            'No classes added yet.\nTap the + button to create a course.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
        );
      }

      final classDocs = snapshot.data!.docs;

      return ListView.builder(
        itemCount: classDocs.length,
        itemBuilder: (context, index) {
          final data = classDocs[index].data() as Map<String, dynamic>;
          final classInstance = ClassModel.fromFirestore(classDocs[index]);

          return ClassCard(classData: classInstance,userRole: 'lecturer',);
        },
      );
    },
  ),
),
            ],
          ),
        ),
      ),

      // --- Floating Action Button Configuration ---
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff111827), // Matches the Lecturer theme color profile
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddClassScreen(userId: effectiveUid),
            ), // Pass userId to AddClassScreen for Firestore operations
          );
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}