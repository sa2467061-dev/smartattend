import 'package:flutter/material.dart';

class LecturerProfileScreen extends StatelessWidget {
  const LecturerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Color(0xff111827); // Dark lecturer theme color

    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Top Profile Header Block ---
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: themeColor,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Dr. Ahmad Ibrahim',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff111827)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Senior Lecturer',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
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
                  _buildProfileTile(Icons.badge_outlined, 'Staff ID', 'STF99284', themeColor),
                  _buildDivider(),
                  _buildProfileTile(Icons.mail_outline_rounded, 'Email', 'ahmad.ibrahim@uitm.edu.my', themeColor),
                  _buildDivider(),
                  _buildProfileTile(Icons.business_center_outlined, 'Faculty', 'Faculty of Computer & Mathematical Sciences', themeColor),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Preferences & Security Section ---
            _buildSectionHeader('PREFERENCES & SECURITY'),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildInteractiveTile(Icons.lock_outline_rounded, 'Change Password', () {}),
                  _buildDivider(),
                  _buildInteractiveTile(Icons.notifications_none_rounded, 'Notification Settings', () {}),
                  _buildDivider(),
                  _buildInteractiveTile(Icons.help_outline_rounded, 'Help & Support', () {}),
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
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // Clears all application route states and safely drops user back onto the Login page
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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

  // Helper widget to build gray sub-section structural headings
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, right: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.8),
        ),
      ),
    );
  }

  // Reusable display tile for non-editable database info fields
  Widget _buildProfileTile(IconData icon, String label, String value, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          Icon(icon, color: themeColor, size: 22),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: Alignment.centerRight == Alignment.centerRight ? TextAlign.end : TextAlign.start,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xff111827)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Reusable interactive chevron tile for setting paths
  Widget _buildInteractiveTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700, size: 22),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xff111827)),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
    );
  }

  // Thin standard layout divider decoration lines
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