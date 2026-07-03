import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student/student_dashboard.dart';
import 'lecturer/lecturer_dashboard.dart';
import '../screens/signin_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../session/session_manager.dart'; // adjust path to wherever you place this file
import 'app_theme.dart'; // adjust path if app_theme.dart isn't directly under lib/
import 'theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: 'https://tjlkfrcencfhclvetlsz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRqbGtmcmNlbmNmaGNsdmV0bHN6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5NzMwODEsImV4cCI6MjA5NDU0OTA4MX0.imVZvfiKP5Qml9Yj7p_1gJ3buSJlBLO_xbSuzZRl6-E',
  );
  runApp(const SmartAttendApp());
}

final supabase = Supabase.instance.client;

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
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/signin': (context) => const SignInScreen(),
            '/student-dashboard': (context) => const StudentDashboard(),
            '/lecturer-dashboard': (context) => const LecturerDashboard(),
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// SPLASH SCREEN: checks for a saved session and routes accordingly.
// ─────────────────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final session = await SessionManager.getSession();

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    if (session == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final userId = session['userId']!;
    final userRole = session['userRole']!;

    if (userRole == 'student') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => StudentDashboard(userId: userId)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => LecturerDashboard(userId: userId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.domain_verification,
                  size: 48, color: colorScheme.onPrimary),
            ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                text: 'SMART',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onBackground,
                    letterSpacing: 0.5),
                children: [
                  TextSpan(
                    text: 'ATTEND',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(color: colorScheme.primary),
          ],
        ),
      ),
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

        final userDoc = querySnapshot.docs.first;
        final String firestoreUid = userDoc.id;

        await SessionManager.saveSession(
          userId: firestoreUid,
          userRole: selectedRole,
        );

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.domain_verification,
                        size: 32, color: colorScheme.onPrimary),
                  ),
                  const SizedBox(width: 10),
                  Text.rich(
                    TextSpan(
                      text: 'SMART',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onBackground,
                          letterSpacing: 0.5),
                      children: [
                        TextSpan(
                          text: 'ATTEND',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 56),
              Text('Welcome back',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground)),
              const SizedBox(height: 6),
              Text('Sign in to your account',
                  style: TextStyle(
                      color: colorScheme.onSurfaceVariant, fontSize: 15)),
              const SizedBox(height: 28),
              Container(
                height: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(25)),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isStudent = true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isStudent
                                ? colorScheme.surface
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: Center(
                            child: Text(
                              'Student',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _isStudent
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant),
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
                            color: !_isStudent
                                ? colorScheme.surface
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: Center(
                            child: Text(
                              'Lecturer',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: !_isStudent
                                      ? colorScheme.onBackground
                                      : colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text('Email',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: _isStudent
                      ? 'student@uitm.edu.my'
                      : 'lecturer@uitm.edu.my',
                  hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant, fontSize: 14),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  fillColor: colorScheme.surface,
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: colorScheme.onSurfaceVariant)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color:
                              colorScheme.onSurfaceVariant.withOpacity(0.4))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: colorScheme.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Password',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant, fontSize: 14),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  fillColor: colorScheme.surface,
                  filled: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: colorScheme.onSurfaceVariant,
                        size: 20),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: colorScheme.onSurfaceVariant)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color:
                              colorScheme.onSurfaceVariant.withOpacity(0.4))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: colorScheme.primary, width: 1.5)),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text('Forgot password?',
                      style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                  side: BorderSide(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isLoading ? null : _loginWithFirestore,
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: colorScheme.onBackground))
                    : Text('Log In',
                        style: TextStyle(
                            color: colorScheme.onBackground,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pushNamed(context, '/signin'),
                child: Text('Sign Up',
                    style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
