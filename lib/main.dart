import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app_theme.dart';

// Screen Imports
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signin_screen.dart';
import 'student/student_dashboard.dart';
import 'lecturer/lecturer_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const SmartAttendApp());
}

class SmartAttendApp extends StatelessWidget {
  const SmartAttendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMARTATTEND',
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signin': (context) => const SignInScreen(),
        '/student-dashboard': (context) => const StudentDashboard(),
         '/lecturer-dashboard': (context) => const LecturerDashboard(),
      },
    );
  }
}


