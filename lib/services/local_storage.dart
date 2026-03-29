import 'package:shared_preferences/shared_preferences.dart';

class AppLocalStorage {

  static Future<void> saveLogin(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isLoggedIn", true);
    await prefs.setString("phone", phone);
    await prefs.setBool("isWorker", false);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("isLoggedIn") ?? false;
  }

  static Future<String?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("phone");
  }

  static Future<void> saveWorkerLogin(String phone, int workerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isLoggedIn", true);
    await prefs.setString("phone", phone);
    await prefs.setBool("isWorker", true);
    await prefs.setInt("workerId", workerId);
  }

  static Future<bool> isWorker() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("isWorker") ?? false;
  }

  static Future<int?> getWorkerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("workerId");
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}