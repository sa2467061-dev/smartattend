import 'package:flutter/material.dart';

class StudentHistoryScreen extends StatelessWidget {
  final VoidCallback? onProfilePressed; // Pass this from the parent dashboard to allow profile switching

  const StudentHistoryScreen({super.key, this.onProfilePressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        titleSpacing: 16,
        automaticallyImplyLeading: false,
        title: Row(
          children: const [
            // App Logo Placeholder
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 2, // Placeholder log entries
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  index == 0 ? Icons.check_circle : Icons.error_outline_rounded,
                  color: index == 0 ? Colors.green : Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        index == 0 ? 'Mobile App Development' : 'Object-Oriented Programming',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        index == 0 ? 'Today • 10:05 AM (Verified)' : 'Yesterday • 02:15 PM (Absent)',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: index == 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    index == 0 ? 'Present' : 'Absent',
                    style: TextStyle(
                      color: index == 0 ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}