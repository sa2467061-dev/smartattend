import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isStudent = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _matrixController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _matrixController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> handleSignUp() async {
    final name = _nameController.text.trim();
    final matrix = _matrixController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all mandatory fields');
      return;
    }

    if (_isStudent && matrix.isEmpty) {
      _showSnackBar('Please provide your Matrix Number');
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String role = _isStudent ? 'student' : 'lecturer';
      final Map<String, dynamic> userData = {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'created_at': FieldValue.serverTimestamp(),
      };

      if (_isStudent) {
        userData['matrix_no'] = matrix;
      }

      await FirebaseFirestore.instance.collection('users').add(userData);
      if (!mounted) return;
      _showSnackBar('Account created successfully!', isError: false);
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      _showSnackBar('Failed to save account: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign up to get started',
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15),
              ),
              const SizedBox(height: 28),
              Container(
                height: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isStudent = true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isStudent ? colorScheme.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: Center(
                            child: Text(
                              'Student',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _isStudent ? colorScheme.primary : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isStudent = false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: !_isStudent ? colorScheme.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: Center(
                            child: Text(
                              'Lecturer',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: !_isStudent ? colorScheme.onBackground : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _buildLabel('Full Name', colorScheme),
              const SizedBox(height: 8),
              _buildTextField(_nameController, 'e.g., Ahmad Ibrahim', colorScheme),
              const SizedBox(height: 20),
              if (_isStudent) ...[
                _buildLabel('Matrix Number', colorScheme),
                const SizedBox(height: 8),
                _buildTextField(_matrixController, 'e.g., 2024288464', colorScheme),
                const SizedBox(height: 20),
              ],
              _buildLabel('Email Address', colorScheme),
              const SizedBox(height: 8),
              _buildTextField(
                _emailController,
                _isStudent ? 'student@uitm.edu.my' : 'lecturer@uitm.edu.my',
                colorScheme,
              ),
              const SizedBox(height: 20),
              _buildLabel('Password', colorScheme),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _buildInputDecoration('••••••••', colorScheme).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel('Confirm Password', colorScheme),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: _buildInputDecoration('••••••••', colorScheme).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isStudent ? colorScheme.primary : colorScheme.onPrimary,
                  foregroundColor: _isStudent ? colorScheme.onPrimary : colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : handleSignUp,
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _isStudent ? colorScheme.onPrimary : colorScheme.primary,
                        ),
                      )
                    : const Text(
                        'Sign Up',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, ColorScheme colorScheme) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.text,
      decoration: _buildInputDecoration(hint, colorScheme),
    );
  }

  Widget _buildLabel(String text, ColorScheme colorScheme) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurfaceVariant,
        fontSize: 14,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, ColorScheme colorScheme) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }
}
