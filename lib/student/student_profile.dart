import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentProfileScreen extends StatelessWidget {
  final String? userId; // Receive the pipeline context parameter

  const StudentProfileScreen({
    super.key,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Establish local tracking fallback parameter safely
    final String? effectiveUid = userId ?? FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: effectiveUid != null
            ? FirebaseFirestore.instance.collection('users').doc(effectiveUid).get()
            : null,
        builder: (context, snapshot) {
          // Default structural local UI fallbacks
          String studentName = 'Student';
          String emailAddress = FirebaseAuth.instance.currentUser?.email ?? 'No email linked';
          String studentId = 'N/A';
          String facultyName = 'Faculty of Computer & Mathematical Sciences';

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data != null) {
              studentName = data['name'] ?? studentName;
              emailAddress = data['email'] ?? emailAddress;
              // Checks database naming pattern metrics dynamically
              studentId = data['student_id'] ?? data['id'] ?? studentId;
              facultyName = data['faculty'] ?? facultyName;
            }
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xff004ce6)));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // --- Top Profile Header Layout ---
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28.0),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 45,
                        backgroundColor: Color(0xff004ce6),
                        child: Icon(Icons.person, size: 50, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        studentName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Undergraduate Student',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // --- Account Information Section ---
                _buildSectionHeader('ACCOUNT INFORMATION'),
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      _buildProfileTile(context, Icons.badge_outlined, 'Student ID', studentId),
                      _buildDivider(),
                      _buildProfileTile(context, Icons.mail_outline_rounded, 'Email', emailAddress),
                      _buildDivider(),
                      _buildProfileTile(context, Icons.business_center_outlined, 'Faculty', facultyName),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // --- Settings Section ---
                _buildSectionHeader('PREFERENCES & SECURITY'),
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      _buildInteractiveTile(context, Icons.lock_outline_rounded, 'Update Password', () {}),
                      _buildDivider(),
                      _buildInteractiveTile(context, Icons.help_outline_rounded, 'Help Support', () {}),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // --- Log Out Action Button ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xfffee2e2), // Soft error red container background
                        foregroundColor: const Color(0xff991b1b),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/login', (route) => false);
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text(
                        'Log Out',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, right: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTile(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff111827), size: 22),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xff111827),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveTile(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.grey.shade700,
        size: 22,
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xff111827),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.grey.shade100,
    );
  }
}