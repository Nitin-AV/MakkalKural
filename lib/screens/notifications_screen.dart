import 'package:flutter/material.dart';
import 'package:smart_civic_connect/utils/my_navigator.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),

      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 25),
            decoration: const BoxDecoration(
              color: Color(0xFF4A90E2),
            ),
            child: const Center(
              child: Text(
                "Notifications",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Expanded(
            child: Center(
              child: Text(
                "Notifications Screen\n(Under Build)",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 70,
        margin: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.grey),
              onPressed: () {
                MyNavigator.goHome(context);
              },
            ),
            IconButton(
              icon: const Icon(Icons.assignment_outlined,
                  color: Colors.grey),
              onPressed: () {
                MyNavigator.goComplaints(context);
              },
            ),
            const Icon(
              Icons.notifications_none,
              color: Color(0xFF4A90E2),
            ),
          ],
        ),
      ),
    );
  }
}