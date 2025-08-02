// lib/api/local_storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalAuthService {
  // --- Key Definitions ---
  static const String _authTokenKey = 'authToken'; // For your custom backend token (sid)
  static const String _userTypeKey = 'userType';   // For the user's approval status
  static const String _userProfileKey = 'userProfile';
  static const String _blockedNumbersKey = 'blockedNumbers';
  static const String _reportedNumbersKey = 'reportedNumbers';

  // --- Auth Token Management ---

  /// Saves the custom authentication token (sid) from your backend.
  Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
  }

  /// Retrieves the custom authentication token.
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  // --- User Type Management ---

  /// Saves the user's type (1 for pending, 2 for approved).
  Future<void> saveUserType(int userType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userTypeKey, userType);
  }

  /// Retrieves the user's type.
  Future<int?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userTypeKey);
  }

  // --- Profile and Status Management ---

  /// Checks if a user token exists, indicating they have started the registration process.
  Future<bool> hasToken() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// Clears all authentication and profile data upon logout or access revocation.
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    await prefs.remove(_userTypeKey);
    await prefs.remove(_userProfileKey);
    await prefs.remove(_reportedNumbersKey);
    await prefs.remove(_blockedNumbersKey);
  }

  // --- User Profile (No changes needed here) ---
  Future<void> saveUserProfile(Map<String, String> profileData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProfileKey, json.encode(profileData));
  }

  Future<Map<String, String>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? profileString = prefs.getString(_userProfileKey);
    if (profileString != null) {
      return Map<String, String>.from(json.decode(profileString));
    }
    return {};
  }
}

// --- Local Reported Numbers (No changes needed here) ---
class LocalReportedNumbersStorage {
  static const String _reportedNumbersKey = 'reportedNumbers';
  LocalReportedNumbersStorage._();
  static final instance = LocalReportedNumbersStorage._();

  Future<void> addReportedNumber(Map<String, dynamic> report) async {
    final prefs = await SharedPreferences.getInstance();
    List<dynamic> currentReports = [];
    final String? reportsString = prefs.getString(_reportedNumbersKey);
    if (reportsString != null) {
      currentReports = json.decode(reportsString);
    }
    currentReports.add(report);
    await prefs.setString(_reportedNumbersKey, json.encode(currentReports));
  }

  Future<List<Map<String, dynamic>>> getReportedNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? reportsString = prefs.getString(_reportedNumbersKey);
    if (reportsString != null) {
      final List<dynamic> decoded = json.decode(reportsString);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<void> clearReportedNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reportedNumbersKey);
  }
}
