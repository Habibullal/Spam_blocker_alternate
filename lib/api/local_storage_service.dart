// local_storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Import for JSON encoding/decoding

class LocalAuthService {
  static const String _authStatusKey = 'isLoggedIn';
  static const String _userProfileKey = 'userProfile';

  // NEW: Key for locally stored blocked numbers
  static const String _blockedNumbersKey = 'blockedNumbers'; 

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
    await prefs.remove(_userProfileKey); // Clear profile on logout
    await prefs.remove(LocalReportedNumbersStorage._reportedNumbersKey); // Clear reported numbers
    await prefs.remove(_blockedNumbersKey); // NEW: Clear locally stored blocked numbers
  }

  // Save user profile data
  Future<void> saveUserProfile(Map<String, String> profileData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProfileKey, json.encode(profileData));
  }

  // Get user profile data
  Future<Map<String, String>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? profileString = prefs.getString(_userProfileKey);
    if (profileString != null) {
      return Map<String, String>.from(json.decode(profileString));
    }
    return {};
  }
}

class LocalBlockedNumbersStorage {
  static const _authStatusKey = 'blockedNumbers';
  LocalBlockedNumbersStorage._();
  static final instance = LocalBlockedNumbersStorage._();
  Set<String> _cache = {};

  Future<Set<String>> getNumbers() async {
    if (_cache.isNotEmpty) {
      return _cache;
    }
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getString(_authStatusKey) ?? "";
    print("Cost");

    _cache = list.split("|").toSet();
    return _cache;
  }

  Future<void> updateNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_authStatusKey, _cache.join("|"));
  }

  void addNumbers(String number) {
    _cache.add(number);
    updateNumbers();
  }

  void createNumber(String number) {
    _cache.add(number);
    updateNumbers();
  }

  bool numberPresent(String number) {
    return _cache.contains(number);
  }
}


// New class for managing locally reported numbers
class LocalReportedNumbersStorage {
  static const String _reportedNumbersKey = 'reportedNumbers';
  LocalReportedNumbersStorage._();
  static final instance = LocalReportedNumbersStorage._();

  // Add a reported number to local storage
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

  // Get all reported numbers from local storage
  Future<List<Map<String, dynamic>>> getReportedNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? reportsString = prefs.getString(_reportedNumbersKey);
    if (reportsString != null) {
      final List<dynamic> decoded = json.decode(reportsString);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  // Clear all reported numbers from local storage
  Future<void> clearReportedNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reportedNumbersKey);
  }
}