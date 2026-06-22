import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // Declared directly here so it defaults to Student view when opened
  bool _isStudent = true; 

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Controllers for all required inputs
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

  void handleSignUp() {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match!')),
      );
      return;
    }

    // placeholder navigation stack clear targeting dashboards
    if (_isStudent) {
      Navigator.pushNamedAndRemoveUntil(context, '/student-dashboard', (route) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/lecturer-dashboard', (route) => false);
    }
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
          onPressed: () => Navigator.pop(context), // Goes back to LoginScreen
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
                onPressed: handleSignUp,
                child: const Text(
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