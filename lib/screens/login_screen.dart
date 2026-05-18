import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Global form keys for validation if needed later
  final _studentFormKey = GlobalKey<FormState>();
  final _teacherFormKey = GlobalKey<FormState>();

  // Text controllers to capture input data
  final TextEditingController _studentEmailController = TextEditingController();
  final TextEditingController _studentPasswordController =
      TextEditingController();
  final TextEditingController _teacherEmailController = TextEditingController();
  final TextEditingController _teacherPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;

  // Shared brand gradient
  static const List<Color> brandGradient = [
    Color(0xFF0F3A6B), // Deep Blue/Teal
    Color(0xFF007A53), // Deep Green
  ];

  @override
  void dispose() {
    _studentEmailController.dispose();
    _studentPasswordController.dispose();
    _teacherEmailController.dispose();
    _teacherPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs: Student and Lecturer
      child: Scaffold(
        backgroundColor: const Color(
          0xFF0F3A6B,
        ), // Matches the top gradient depth
        body: Column(
          children: [
            // --- TOP GRADIENT HEADER ---
            Container(
              width: double.infinity,
              height: 160,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: brandGradient,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: const SafeArea(
                bottom: false,
                child: Center(
                  child: Text(
                    'Identify Yourself',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // --- BOTTOM WHITE LOGIN CARD ---
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32.0),
                    topRight: Radius.circular(32.0),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // --- TAB BAR NAVIGATION ---
                    TabBar(
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.black38,
                      indicatorColor: Colors.black54,
                      indicatorWeight: 3.0,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                      tabs: const [
                        Tab(text: 'STUDENT LOGIN'),
                        Tab(text: 'LECTURER LOGIN'),
                      ],
                    ),

                    // --- TAB VIEWS FOR FORMS ---
                    Expanded(
                      child: TabBarView(
                        children: [
                          // 1. Student Login View
                          _buildLoginForm(
                            formKey: _studentFormKey,
                            emailController: _studentEmailController,
                            passwordController: _studentPasswordController,
                            onLoginPressed: () {
                              // Action when Student logs in successfully
                              Navigator.pushReplacementNamed(
                                context,
                                '/student_home',
                              );
                            },
                          ),

                          // 2. Lecturer/Teacher Login View
                          _buildLoginForm(
                            formKey: _teacherFormKey,
                            emailController: _teacherEmailController,
                            passwordController: _teacherPasswordController,
                            onLoginPressed: () {
                              // Action when Teacher logs in successfully
                              Navigator.pushReplacementNamed(
                                context,
                                '/teacher_home',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Generic Reusable Form Builder for both tabs
  Widget _buildLoginForm({
    required GlobalKey<FormState> formKey,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required VoidCallback onLoginPressed,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            // --- EMAIL FIELD ---
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email or username',
                hintStyle: const TextStyle(color: Colors.black38),
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: Colors.black38,
                ),
                filled: true,
                fillColor: const Color(0xFFF2F4F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 18.0),
              ),
            ),
            const SizedBox(height: 20),

            // --- PASSWORD FIELD ---
            TextFormField(
              controller: passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: const TextStyle(color: Colors.black38),
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: Colors.black38,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.black38,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                filled: true,
                fillColor: const Color(0xFFF2F4F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 18.0),
              ),
            ),
            const SizedBox(height: 40),

            // --- GRADIENT LOGIN BUTTON ---
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: brandGradient,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(28.0),
              ),
              child: ElevatedButton(
                onPressed: onLoginPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.0),
                  ),
                ),
                child: const Text(
                  'LOGIN',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- FORGOT PASSWORD LINK ---
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Action for forgot password
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- REGISTER LINK ---
            TextButton(
              onPressed: () {
                // Action for registration page
              },
              child: const Text(
                'Register (New User)',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
