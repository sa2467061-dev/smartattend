import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  final bool isStudent;
  const SignInScreen({super.key, required this.isStudent});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  void handleSignIn() {
    if (widget.isStudent) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/student_dashboard', (route) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(
          context, '/lecturer_dashboard', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isStudent ? 'Student Login' : 'Lecturer Login',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text('Welcome Back',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            Text(
              widget.isStudent
                  ? 'Sign in to mark your attendance'
                  : 'Sign in to manage attendance',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 36),
            Text(widget.isStudent ? 'Student ID' : 'Email',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _idController,
              decoration: InputDecoration(
                prefixIcon: Icon(widget.isStudent
                    ? Icons.email_outlined
                    : Icons.mail_outline),
                hintText: widget.isStudent
                    ? '2024288464'
                    : 'ahmad.ibrahim@university.edu.my',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Password',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                hintText: '••••••••',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff004ce6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: handleSignIn,
                child: const Text('Sign In',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
