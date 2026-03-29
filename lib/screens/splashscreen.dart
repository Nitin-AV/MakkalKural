import 'package:flutter/material.dart';
import 'package:smart_civic_connect/screens/homescreen.dart';
import 'package:smart_civic_connect/screens/worker/worker_home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_storage.dart';
import 'login/location_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  void checkLogin() async {
    final loggedIn = await AppLocalStorage.isLoggedIn();

    if (!loggedIn) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LocationScreen()),
      );
      return;
    }

    final isWorker = await AppLocalStorage.isWorker();

    if (isWorker) {
      final workerId = await AppLocalStorage.getWorkerId();
      if (workerId != null) {
        try {
          final workerData = await Supabase.instance.client
              .from('workers')
              .select('id, name, phone, ward_name')
              .eq('id', workerId)
              .single();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => WorkerHomeScreen(workerData: workerData),
            ),
          );
          return;
        } catch (_) {}
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}