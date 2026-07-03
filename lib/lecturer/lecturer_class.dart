import 'package:flutter/material.dart';
//import '../lecturer/lecturer_profile.dart'; // Ensure correct import for profile navigation
import '../lecturer/add_class.dart'; // Imports your custom screen path
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
    final String? effectiveUid =
        userId ?? FirebaseAuth.instance.currentUser?.uid;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // --- Consistent Top Bar Layout ---
      appBar: AppBar(
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        foregroundColor:
            theme.appBarTheme.foregroundColor ?? colorScheme.onSurface,
        elevation: 0.5,
        titleSpacing: 16,
        title: Row(
          children: [
            Icon(Icons.domain_verification,
                color: colorScheme.primary, size: 28),
            const SizedBox(width: 8),
            Text(
              'SMARTATTEND',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 0.5,
                  color: colorScheme.onSurface),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: onProfilePressed, // Seamless profile access layout overlay
              child: CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primary,
                child:
                    Icon(Icons.person, color: colorScheme.onPrimary, size: 20),
              ),
            ),
          ),
        ],
      ),

      // --- Main View Content ---
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Classes',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage and track your assigned courses here.',
                style: TextStyle(
                    color: colorScheme.onSurfaceVariant, fontSize: 14),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('classes')
                      .where('lect_id',
                          isEqualTo:
                              effectiveUid) // Filters by logged-in lecturer
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No classes added yet.\nTap the + button to create a course.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant, height: 1.5),
                        ),
                      );
                    }

                    final classDocs = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: classDocs.length,
                      itemBuilder: (context, index) {
                        final classInstance =
                            ClassModel.fromFirestore(classDocs[index]);

                        return ClassCard(
                          classData: classInstance,
                          userRole: 'lecturer',
                          userId: effectiveUid ?? '',
                        );
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
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddClassScreen(userId: effectiveUid),
            ), // Pass userId to AddClassScreen for Firestore operations
          );
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
