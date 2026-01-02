import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/report_provider.dart';
import 'views/auth/login_screen.dart';
import 'models/user_account.dart';
import 'views/admin/admin_dashboard.dart';
import 'views/member/member_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCoks37eTygyAdNPcUwqCOoPKOQxFNG_ZA",
          authDomain: "ebz-attendance.firebaseapp.com",
          projectId: "ebz-attendance",
          storageBucket: "ebz-attendance.firebasestorage.app",
          messagingSenderId: "803173085858",
          appId: "1:803173085858:web:2031f11a69cd9994bdddfb",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: MaterialApp(
        title: 'EbzAttendance',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blueAccent,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authProvider.currentUser == null) {
      return const LoginScreen();
    }

    final user = authProvider.currentUser!;

    if (kIsWeb) {
      if (user.role == UserRole.admin) {
        return const AdminDashboard();
      } else {
        return const UnsupportedPlatformScreen(
          message: 'Member access is available only on the mobile app.',
        );
      }
    } else {
      if (user.role == UserRole.member) {
        return const MemberDashboard();
      } else {
        return const UnsupportedPlatformScreen(
          message: 'Admin access is available only on the web portal.',
        );
      }
    }
  }
}

class UnsupportedPlatformScreen extends StatelessWidget {
  final String message;
  const UnsupportedPlatformScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Restricted'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phonelink_erase, size: 80, color: Colors.redAccent),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please use the appropriate device to access your dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
