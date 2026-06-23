import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LecturerHistoryScreen extends StatelessWidget {
  final VoidCallback onProfilePressed;
  final String? userId; // 1. Add the variable parameter field

  const LecturerHistoryScreen({
    super.key,
    required this.onProfilePressed,
    this.userId, // 2. Add it to your constructor setup
  });

  @override
  Widget build(BuildContext context) {
    // Safely capture a clean local UID fallback via active Firebase Auth instance
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
              onTap: onProfilePressed,
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xff111827),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      
      // --- History List Body ---
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attendance History',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xff111827)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Review details and total turnouts of past geofenced check-ins.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              
              Expanded(
                child: ListView(
                  children: [
                    _buildHistoryCard(
                      className: 'Advanced Mobile Computing',
                      classCode: 'ITS652',
                      date: 'Today, 22 June 2026',
                      time: '2:00 PM - 4:00 PM',
                      presentCount: 38,
                      totalCount: 40,
                    ),
                    const SizedBox(height: 14),
                    _buildHistoryCard(
                      className: 'Object-Oriented Programming',
                      classCode: 'ITS422',
                      date: '18 June 2026',
                      time: '10:00 AM - 12:00 PM',
                      presentCount: 42,
                      totalCount: 45,
                    ),
                    const SizedBox(height: 14),
                    _buildHistoryCard(
                      className: 'Web Application Development',
                      classCode: 'ITS553',
                      date: '15 June 2026',
                      time: '8:30 AM - 10:30 AM',
                      presentCount: 35,
                      totalCount: 35,
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

  // Helper widget to structure past session attendance metrics cleanly
  Widget _buildHistoryCard({
    required String className,
    required String classCode,
    required String date,
    required String time,
    required int presentCount,
    required int totalCount,
  }) {
    final bool isFullHouse = presentCount == totalCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classCode,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  className,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff111827)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(date, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(time, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isFullHouse ? const Color(0xff10b981).withAlpha(20) : const Color(0xffe9ecef),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$presentCount/$totalCount',
                  style: TextStyle(
                    fontSize: 15, 
                    fontWeight: FontWeight.bold, 
                    color: isFullHouse ? const Color(0xff10b981) : const Color(0xff111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Attended',
                  style: TextStyle(
                    fontSize: 11, 
                    fontWeight: FontWeight.w500, 
                    color: isFullHouse ? const Color(0xff10b981) : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}