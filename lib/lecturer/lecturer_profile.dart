import 'package:flutter/material.dart';
import '../main.dart';

class LecturerProfileScreen extends StatelessWidget {
  const LecturerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color themeColor = isDark ? Colors.white : const Color(0xff111827);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xff121212) : const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xff1e1e1e) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0.5,
        title: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          // Dark mode toggle
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, mode, _) {
              return IconButton(
                icon: Icon(
                  mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                  color: isDark ? Colors.white : const Color(0xff111827),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Top Profile Header Block ---
            Container(
              color: isDark ? const Color(0xff1e1e1e) : Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: isDark ? Colors.white24 : const Color(0xff111827),
                    child: const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Dr. Ahmad Ibrahim',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xff111827),
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
            _buildSectionHeader('ACCOUNT INFORMATION', isDark),
            Container(
              color: isDark ? const Color(0xff1e1e1e) : Colors.white,
              child: Column(
                children: [
                  _buildProfileTile(Icons.badge_outlined, 'Staff ID', 'STF99284', themeColor, isDark),
                  _buildDivider(isDark),
                  _buildProfileTile(Icons.mail_outline_rounded, 'Email', 'ahmad.ibrahim@uitm.edu.my', themeColor, isDark),
                  _buildDivider(isDark),
                  _buildProfileTile(Icons.business_center_outlined, 'Faculty', 'Faculty of Computer & Mathematical Sciences', themeColor, isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Preferences & Security Section ---
            _buildSectionHeader('PREFERENCES & SECURITY', isDark),
            Container(
              color: isDark ? const Color(0xff1e1e1e) : Colors.white,
              child: Column(
                children: [
                  _buildInteractiveTile(Icons.lock_outline_rounded, 'Change Password', () {}, isDark),
                  _buildDivider(isDark),
                  _buildInteractiveTile(Icons.notifications_none_rounded, 'Notification Settings', () {}, isDark),
                  _buildDivider(isDark),
                  _buildInteractiveTile(Icons.help_outline_rounded, 'Help & Support', () {}, isDark),
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
                    backgroundColor: isDark
                        ? Colors.red.shade900.withAlpha(120)
                        : Colors.red.shade50,
                    foregroundColor: isDark
                        ? Colors.red.shade300
                        : Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (route) => false);
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
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
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

  Widget _buildProfileTile(
      IconData icon, String label, String value, Color themeColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          Icon(icon, color: themeColor, size: 22),
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
                color: isDark ? Colors.white : const Color(0xff111827),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveTile(
      IconData icon, String label, VoidCallback onTap, bool isDark) {
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
          color: isDark ? Colors.white : const Color(0xff111827),
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

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: isDark ? Colors.white10 : Colors.grey.shade100,
    );
  }
}