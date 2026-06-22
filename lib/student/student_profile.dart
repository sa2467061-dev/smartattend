import 'package:flutter/material.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _isDarkMode = false; // State holder for the dark mode switch/slider

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff1f2937))),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false, // Removes default left back arrow
        actions: [
          // Back button moved explicitly to the top right corner
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xff1f2937)),
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
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xff004ce6),
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ahmad Ibrahim',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Faculty of Computer Science',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            
            // Student Info Cards
            _buildProfileTile(Icons.badge_outlined, 'Student ID', '2024288464'),
            const SizedBox(height: 12),
            _buildProfileTile(Icons.smartphone_rounded, 'Device Link Status', 'Linked Device (SMART-V1)'),
            const SizedBox(height: 12),
            _buildProfileTile(Icons.analytics_outlined, 'Overall Attendance', '94.2% (Target Achieved)'),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            // --- SETTINGS / ACTIONS LIST ---
            
            // Change Profile Option
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Color(0xff1f2937)),
              title: const Text('Change Profile', style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                // Action to change profile image/details
              },
            ),

            // Dark Mode Option (Switch Slider)
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined, color: Color(0xff1f2937)),
              title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w500)),
              activeColor: const Color(0xff004ce6),
              value: _isDarkMode,
              onChanged: (bool value) {
                setState(() {
                  _isDarkMode = value;
                });
              },
            ),
            
            const SizedBox(height: 32),

            // Red Logout Button
            ElevatedButton.icon(
              onPressed: () {
                // Wipe navigation stack back to Login
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size.fromHeight(50), // Makes button full width
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.shade200),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text(
                'Log Out',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfff9fafb),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff004ce6)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xff1f2937))),
            ],
          )
        ],
      ),
    );
  }
}