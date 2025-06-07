import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthService {
  static const String _authStatusKey = 'isLoggedIn';

  // Check if the user is marked as logged in locally
  Future<bool> isUserLoggedInLocally() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_authStatusKey) ?? false;
  }

  // Save the logged-in status to the device
  Future<void> saveLoginStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_authStatusKey, isLoggedIn);
  }

  // Clear the logged-in status (for logout)
  Future<void> clearLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authStatusKey);
  }
}