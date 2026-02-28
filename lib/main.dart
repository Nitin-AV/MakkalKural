import 'package:smart_civic_connect/constants/api_constants.dart';
import 'package:smart_civic_connect/screens/complaints_screen.dart';
import 'package:smart_civic_connect/screens/notifications_screen.dart';
import 'package:smart_civic_connect/screens/report_issue_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/splashscreen.dart';
import 'screens/login/location_screen.dart';
import 'screens/homescreen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await Supabase.initialize(
    url: ApiConstants.supabaseUrl,
    anonKey: ApiConstants.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Smart Civic Connect",
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
        ),
      ),
      initialRoute: "/",
      routes: {
        "/": (context) => const SplashScreen(),
        "/location": (context) => const LocationScreen(),
        "/home": (context) => const HomeScreen(),
        "/report": (context) => const ReportIssueScreen(),
        "/complaints": (context) => const ComplaintsScreen(),
        "/notifications": (context) => const NotificationsScreen(),
      },
    );
  }
}