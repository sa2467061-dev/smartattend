import 'package:flutter/material.dart';
import '../main.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xff121212) : Colors.white,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xff1f2937),
          ),
        ),
        backgroundColor: isDark ? const Color(0xff1e1e1e) : Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : const Color(0xff1f2937),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // --- Profile Avatar ---
            CircleAvatar(
              radius: 50,
              backgroundColor: isDark ? const Color(0xff1a3a8f) : const Color(0xff004ce6),
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),

            // --- Name & Faculty ---
            Text(
              'Ahmad Ibrahim',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xff1f2937),
              ),
            ),
            Text(
              'Faculty of Computer Science',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // --- Student Info Cards ---
            _buildProfileTile(
              Icons.badge_outlined,
              'Student ID',
              '2024288464',
              isDark,
            ),
            const SizedBox(height: 12),
            _buildProfileTile(
              Icons.smartphone_rounded,
              'Device Link Status',
              'Linked Device (SMART-V1)',
              isDark,
            ),
            const SizedBox(height: 12),
            _buildProfileTile(
              Icons.analytics_outlined,
              'Overall Attendance',
              '94.2% (Target Achieved)',
              isDark,
            ),

            const SizedBox(height: 24),
            Divider(color: isDark ? Colors.white12 : Colors.grey.shade200),
            const SizedBox(height: 12),

            // --- Change Profile Option ---
            ListTile(
              leading: Icon(
                Icons.edit_outlined,
                color: isDark ? Colors.white70 : const Color(0xff1f2937),
              ),
              title: Text(
                'Change Profile',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xff1f2937),
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white38 : Colors.grey,
              ),
              onTap: () {},
            ),

            // --- Dark Mode Switch (wired to themeNotifier) ---
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, mode, _) {
                return SwitchListTile(
                  secondary: Icon(
                    Icons.dark_mode_outlined,
                    color: isDark ? Colors.white70 : const Color(0xff1f2937),
                  ),
                  title: Text(
                    'Dark Mode',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xff1f2937),
                    ),
                  ),
                  activeThumbColor: const Color(0xff004ce6),
                  activeTrackColor: const Color(0xff004ce6).withAlpha(80),
                  value: mode == ThemeMode.dark,
                  onChanged: (bool value) {
                    themeNotifier.value =
                        value ? ThemeMode.dark : ThemeMode.light;
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // --- Log Out Button ---
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? Colors.red.shade900.withAlpha(120)
                    : Colors.red.shade50,
                foregroundColor:
                    isDark ? Colors.red.shade300 : Colors.red,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark
                        ? Colors.red.shade800
                        : Colors.red.shade200,
                  ),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text(
                'Log Out',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(
      IconData icon, String title, String subtitle, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff1e1e1e) : const Color(0xfff9fafb),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDark ? const Color(0xff4d8ef0) : const Color(0xff004ce6),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xff1f2937),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}