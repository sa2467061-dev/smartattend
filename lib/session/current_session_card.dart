import 'package:flutter/material.dart';
import '../session/session_model.dart'; // adjust import path to match your project structure
import '../session/session_detail_screen.dart'; // adjust import path to match your project structure

/// Big, prominent card shown on the dashboard when a session is currently
/// active (now falls within the session's time_slot). Tapping it opens the
/// full SessionDetailScreen, which branches its content by role.
class CurrentSessionCard extends StatelessWidget {
  final SessionModel session;
  final String className; // e.g. "ITS652" - passed in since SessionModel doesn't store it
  final String userId;
  final String userRole; // 'student' | 'lecturer'

  const CurrentSessionCard({
    super.key,
    required this.session,
    required this.className,
    required this.userId,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SessionDetailScreen(
              session: session,
              className: className,
              userId: userId,
              userRole: userRole,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xff004ce6),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff004ce6).withAlpha(60),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                const Text(
                  'LIVE NOW',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              className,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    session.locationName,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${_formatTime(session.startTime)} - ${_formatTime(session.endTime)}',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  userRole == 'lecturer' ? 'View Live Attendance' : 'Tap to Mark Attendance',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}