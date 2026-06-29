import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 1. IMPORT CLOUD FIRESTORE

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isStudent = true; 
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false; // 2. MANAGING DATABASE SUBMIT STATE

  final _nameController = TextEditingController();
  final _matrixController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _matrixController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 3. UPDATED METHOD TO WRITE DATA TO FIRESTORE
  Future<void> handleSignUp() async {
    final name = _nameController.text.trim();
    final matrix = _matrixController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Field validations
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

      // Assemble base user map
      final Map<String, dynamic> userData = {
        'name': name,
        'email': email,
        'password': password, // Note: Consider encryption/Firebase Auth for secure production environments
        'role': role,
        'created_at': FieldValue.serverTimestamp(),
      };

      // 4. CONDITIONAL MATRIX DATA STRATEGY
      if (_isStudent) {
        userData['matrix_no'] = matrix;
      }

      // Add document to your 'users' collection
      await FirebaseFirestore.instance.collection('users').add(userData);

      if (!mounted) return;

      _showSnackBar('Account created successfully!', isError: false);

      // Route dynamically across dashboards
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
        backgroundColor: isError ? Colors.redAccent : Colors.green
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: const Color(0xfff8f9fa),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff111827)),
          onPressed: () => Navigator.pop(context), 
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create Account',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xff111827)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sign up to get started',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
              const SizedBox(height: 28),

              // --- Sliding Toggle Tab ---
              Container(
                height: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xffe9ecef),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isStudent = true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isStudent ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: Center(
                            child: Text(
                              'Student',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _isStudent ? const Color(0xff004ce6) : Colors.grey.shade600,
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
                            color: !_isStudent ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: Center(
                            child: Text(
                              'Lecturer',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: !_isStudent ? const Color(0xff111827) : Colors.grey.shade600,
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

              // --- Full Name Field ---
              const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xff374151), fontSize: 14)),
              const SizedBox(height: 8),
              _buildTextField(_nameController, 'e.g., Ahmad Ibrahim', TextInputType.name),
              const SizedBox(height: 20),

              // --- Conditional Matrix Number Field (Only for Students) ---
              if (_isStudent) ...[
                const Text('Matrix Number', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xff374151), fontSize: 14)),
                const SizedBox(height: 8),
                _buildTextField(_matrixController, 'e.g., 2024288464', TextInputType.text),
                const SizedBox(height: 20),
              ],

              // --- Email Field ---
              const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xff374151), fontSize: 14)),
              const SizedBox(height: 8),
              _buildTextField(
                _emailController, 
                _isStudent ? 'student@uitm.edu.my' : 'lecturer@uitm.edu.my', 
                TextInputType.emailAddress
              ),
              const SizedBox(height: 20),

              // --- Password Field ---
              const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xff374151), fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _buildInputDecoration('••••••••').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Confirm Password Field ---
              const Text('Confirm Password', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xff374151), fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: _buildInputDecoration('••••••••').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey, size: 20),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- Sign Up Action Button ---
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isStudent ? const Color(0xff004ce6) : const Color(0xff111827),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : handleSignUp, // Disable interaction during active call
                child: _isLoading 
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
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

  Widget _buildTextField(TextEditingController controller, String hint, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: _buildInputDecoration(hint),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), 
        borderSide: BorderSide(color: _isStudent ? const Color(0xff004ce6) : const Color(0xff111827), width: 1.5)
      ),
    );
  }
}