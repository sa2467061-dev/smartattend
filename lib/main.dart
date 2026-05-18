import 'package:flutter/material.dart';
import 'package:smartattend/screens/splash_screen.dart';
import 'package:smartattend/screens/login_screen.dart';
import 'package:smartattend/screens/student_dashboard.dart';
import 'package:smartattend/screens/teacher_dashboard.dart';

void main() {
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Recommended for newer Flutter versions
      ),
      // The app will start on the Splash Screen
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/student_home': (context) => const StudentDashboard(),
        '/teacher_home': (context) => const TeacherDashboard(),
      },
    );
  }
}
