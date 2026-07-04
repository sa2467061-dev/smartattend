import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_manager.dart';
import '../widgets/help_support_dialog.dart';

class StudentProfileScreen extends StatelessWidget {
  final String? userId;

  const StudentProfileScreen({
    super.key,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final String? effectiveUid =
        userId ?? FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Profile',
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
                  themeNotifier.value =
                      mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
        ],
      ),
      body: effectiveUid == null
          ? Center(
              child: Text(
                'Unable to load profile.',
                style: TextStyle(color: colorScheme.onSurface),
              ),
            )
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(effectiveUid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(
                          color: colorScheme.primary));
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    !snapshot.data!.exists) {
                  return Center(
                    child: Text(
                      'Error loading profile.',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final String studentName =
                    data?['name']?.toString() ?? 'Student';
                final String emailAddress =
                    data?['email']?.toString() ?? 'No email linked';
                final String studentId = data?['matrix_no']?.toString() ??
                    data?['id']?.toString() ??
                    'N/A';
                final String facultyName = data?['faculty']?.toString() ??
                    'Faculty of Computer & Mathematical Sciences';

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        color: colorScheme.surface,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 45,
                              backgroundColor: theme.colorScheme.primary,
                              child: const Icon(Icons.person,
                                  size: 50, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              studentName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Undergraduate Student',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionHeader(context, 'ACCOUNT INFORMATION'),
                      Material(
                        color: colorScheme.surface,
                        child: Column(
                          children: [
                            _buildProfileTile(context, Icons.badge_outlined,
                                'Student ID', studentId),
                            _buildDivider(context),
                            _buildProfileTile(
                                context,
                                Icons.mail_outline_rounded,
                                'Email',
                                emailAddress),
                            _buildDivider(context),
                            _buildProfileTile(
                                context,
                                Icons.business_center_outlined,
                                'Faculty',
                                facultyName),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionHeader(context, 'PREFERENCES & SECURITY'),
                      Material(
                        color: colorScheme.surface,
                        child: Column(
                          children: [
                            _buildInteractiveTile(
                              context,
                              Icons.lock_outline_rounded,
                              'Update Password',
                              () => showChangePasswordDialog(
                                  context, effectiveUid),
                            ),
                            _buildDivider(context),
                            _buildInteractiveTile(
                                context,
                                Icons.help_outline_rounded,
                                'Help Support',
                                () => showHelpSupportDialog(context,
                                    isLecturer: false)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
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
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
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
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, right: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTile(
      BuildContext context, IconData icon, String label, String value) {
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
              color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildInteractiveTile(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: theme.colorScheme.onSurfaceVariant,
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
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
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

Future<void> showChangePasswordDialog(BuildContext context, String uid) async {
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();
  bool isLoading = false;
  String? errorText;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Change Password'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final currentPassword = currentController.text.trim();
                        final newPassword = newController.text.trim();
                        final confirmPassword = confirmController.text.trim();

                        if (currentPassword.isEmpty ||
                            newPassword.isEmpty ||
                            confirmPassword.isEmpty) {
                          setState(() {
                            errorText = 'Please fill in all fields.';
                          });
                          return;
                        }

                        if (newPassword.length < 6) {
                          setState(() {
                            errorText =
                                'New password must be at least 6 characters.';
                          });
                          return;
                        }

                        if (newPassword != confirmPassword) {
                          setState(() {
                            errorText = 'Passwords do not match.';
                          });
                          return;
                        }

                        setState(() {
                          isLoading = true;
                          errorText = null;
                        });

                        try {
                          final userDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .get();
                          if (!userDoc.exists) {
                            setState(() {
                              errorText = 'Unable to verify current password.';
                            });
                            return;
                          }

                          final data = userDoc.data() as Map<String, dynamic>?;
                          final storedPassword =
                              data?['password']?.toString() ?? '';

                          if (storedPassword != currentPassword) {
                            setState(() {
                              errorText = 'Current password is incorrect.';
                            });
                            return;
                          }

                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .update({'password': newPassword});

                          final currentUser = FirebaseAuth.instance.currentUser;
                          if (currentUser != null) {
                            try {
                              await currentUser.updatePassword(newPassword);
                            } catch (_) {
                              // ignore
                            }
                          }

                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Password updated successfully.')),
                            );
                          }
                        } catch (_) {
                          setState(() {
                            errorText =
                                'Failed to update password. Please try again.';
                          });
                        } finally {
                          if (context.mounted) {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Update'),
              ),
            ],
          );
        },
      );
    },
  );
}