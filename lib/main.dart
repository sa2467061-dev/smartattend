import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'student/student_dashboard.dart'; 
import 'lecturer/lecturer_dashboard.dart'; 
import '../screens/signin_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); 
  runApp(const SmartAttendApp());
}

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

class SmartAttendApp extends StatelessWidget {
  const SmartAttendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'SMARTATTEND',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          initialRoute: '/login', 
          routes: {
            '/login': (context) => const LoginScreen(),
            '/signin': (context) => const SignInScreen(),
            // Kept basic named routes for fallbacks if needed elsewhere
            '/student-dashboard': (context) => const StudentDashboard(),
            '/lecturer-dashboard': (context) => const LecturerDashboard(),
          },
        );
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isStudent = true;
  bool _obscurePassword = true;
  bool _isLoading = false; 

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _loginWithFirestore() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String selectedRole = _isStudent ? 'student' : 'lecturer';
      
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .where('role', isEqualTo: selectedRole)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        if (!mounted) return;

        // CRITICAL FIX: Extract the actual document ID (uid) from your custom Firestore document
        final userDoc = querySnapshot.docs.first;
        final String firestoreUid = userDoc.id; 

        if (_isStudent) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDashboard(userId: firestoreUid),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LecturerDashboard(userId: firestoreUid),
            ),
          );
        }
      } else {
        _showSnackBar('Invalid credentials or incorrect user role.');
      }
    } catch (e) {
      _showSnackBar('An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa), 
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xff004ce6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.domain_verification, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Text.rich(
                    TextSpan(
                      text: 'SMART',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: Colors.black, letterSpacing: 0.5),
                      children: [
                        TextSpan(
                          text: 'ATTEND',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff004ce6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 56),
              const Text('Welcome back', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xff111827))),
              const SizedBox(height: 6),
              const Text('Sign in to your account', style: TextStyle(color: Colors.grey, fontSize: 15)),
              const SizedBox(height: 28),

              Container(
                height: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: const Color(0xffe9ecef), borderRadius: BorderRadius.circular(25)),
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
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _isStudent ? const Color(0xff004ce6) : Colors.grey.shade600),
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
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: !_isStudent ? const Color(0xff111827) : Colors.grey.shade600),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 28),
              const Text('Email', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xff374151), fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: _isStudent ? 'student@uitm.edu.my' : 'lecturer@uitm.edu.my',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xff004ce6), width: 1.5)),
                ),
              ),
              
              const SizedBox(height: 20),
              const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xff374151), fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  fillColor: Colors.white,
                  filled: true,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xff004ce6), width: 1.5)),
                ),
              ),
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Forgot password?', style: TextStyle(color: Color(0xff004ce6), fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
              
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isLoading ? null : _loginWithFirestore, 
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Log In', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              
              const SizedBox(height: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff004ce6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pushNamed(context, '/signin'),
                child: const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}