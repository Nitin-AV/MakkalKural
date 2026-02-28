import 'package:flutter/material.dart';

class MyNavigator {

  static void goHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (_) => false,
    );
  }

  static void goReport(BuildContext context) {
    Navigator.pushNamed(context, '/report');
  }

  static void goComplaints(BuildContext context) {
    Navigator.pushNamed(context, '/complaints');
  }

  static void goNotifications(BuildContext context) {
    Navigator.pushNamed(context, '/notifications');
  }

  static void logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/location',
      (_) => false,
    );
  }
}