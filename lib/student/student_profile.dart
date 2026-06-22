import 'package:flutter/material.dart';
import '../main.dart'; // Adjust path based on your real location

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  @override
  Widget build(BuildContext context) {
    // Standardizing theme accessors
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
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
              backgroundColor: colorScheme.primary,
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),

            // --- Name & Faculty ---
            Text(
              'Ahmad Ibrahim',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              'Faculty of Computer Science',
              style: TextStyle(
                color: theme.brightness == Brightness.dark ? Colors.white54 : Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // --- Student Info Cards ---
            _buildProfileTile(context, Icons.badge_outlined, 'Student ID', '2024288464'),
            const SizedBox(height: 12),
            _buildProfileTile(context, Icons.smartphone_rounded, 'Device Link Status', 'Linked Device (SMART-V1)'),
            const SizedBox(height: 12),
            _buildProfileTile(context, Icons.analytics_outlined, 'Overall Attendance', '94.2% (Target Achieved)'),

            const SizedBox(height: 24),
            Divider(color: theme.dividerColor),
            const SizedBox(height: 12),

            // --- Change Profile Option ---
            ListTile(
              leading: Icon(Icons.edit_outlined, color: colorScheme.onSurface.withOpacity(0.8)),
              title: Text(
                'Change Profile',
                style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),

            // --- Dark Mode Switch ---
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, mode, _) {
                return SwitchListTile(
                  secondary: Icon(Icons.dark_mode_outlined, color: colorScheme.onSurface.withOpacity(0.8)),
                  title: Text(
                    'Dark Mode',
                    style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                  ),
                  activeColor: colorScheme.primary,
                  value: mode == ThemeMode.dark,
                  onChanged: (bool value) {
                    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // --- Log Out Button ---
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
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

  Widget _buildProfileTile(BuildContext context, IconData icon, String title, String subtitle) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.brightness == Brightness.dark ? Colors.white54 : Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}