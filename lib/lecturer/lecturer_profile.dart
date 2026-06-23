import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart'; // Adjust path based on your real location

class LecturerProfileScreen extends StatelessWidget {
  final String? userId; // 1. Add the variable parameter field

  const LecturerProfileScreen({
    super.key, 
    this.userId, // 2. Add it to your constructor setup
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Safely capture a clean local UID fallback via active instance
    final String? effectiveUid = userId ?? FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xff121212) : const Color(0xfff8f9fa),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, mode, _) {
              return IconButton(
                icon: Icon(
                  mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () {
                  themeNotifier.value = mode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: effectiveUid != null
            ? FirebaseFirestore.instance.collection('users').doc(effectiveUid).get()
            : null,
        builder: (context, snapshot) {
          // Default fallbacks while database loads or if data is absent
          String displayName = 'Lecturer';
          String emailAddress = FirebaseAuth.instance.currentUser?.email ?? 'No email associated';
          String staffId = 'N/A';
          String facultyName = 'Faculty of Computer & Mathematical Sciences';

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data != null) {
              displayName = data['name'] ?? displayName;
              emailAddress = data['email'] ?? emailAddress;
              staffId = data['staff_id'] ?? data['id'] ?? staffId; // Adjust key to match your database field mapping
              facultyName = data['faculty'] ?? facultyName;
            }
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // --- Top Profile Header Block ---
                Container(
                  color: colorScheme.surface,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: isDark ? Colors.white24 : colorScheme.onSurface,
                        child: const Icon(Icons.person, size: 50, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Senior Lecturer',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // --- Account Information Section ---
                _buildSectionHeader(context, 'ACCOUNT INFORMATION'),
                Container(
                  color: colorScheme.surface,
                  child: Column(
                    children: [
                      _buildProfileTile(context, Icons.badge_outlined, 'Staff ID', staffId),
                      _buildDivider(context),
                      _buildProfileTile(context, Icons.mail_outline_rounded, 'Email', emailAddress),
                      _buildDivider(context),
                      _buildProfileTile(context, Icons.business_center_outlined, 'Faculty', facultyName),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // --- Preferences & Security Section ---
                _buildSectionHeader(context, 'PREFERENCES & SECURITY'),
                Container(
                  color: colorScheme.surface,
                  child: Column(
                    children: [
                      _buildInteractiveTile(context, Icons.lock_outline_rounded, 'Change Password', () {}),
                      _buildDivider(context),
                      _buildInteractiveTile(context, Icons.notifications_none_rounded, 'Notification Settings', () {}),
                      _buildDivider(context),
                      _buildInteractiveTile(context, Icons.help_outline_rounded, 'Help & Support', () {}),
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
                        backgroundColor: colorScheme.errorContainer,
                        foregroundColor: colorScheme.onErrorContainer,
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, right: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white38 : Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTile(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurface, size: 22),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : Colors.grey,
            ),
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? Colors.white54 : Colors.grey.shade700,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: isDark ? Colors.white30 : Colors.grey.shade400,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).dividerColor,
    );
  }
}