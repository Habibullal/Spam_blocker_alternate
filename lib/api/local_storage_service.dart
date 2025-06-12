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

class LocalBlockedNumbersStorage{
  static const _authStatusKey = 'blockedNumbers';
  LocalBlockedNumbersStorage._();
  static final instance = LocalBlockedNumbersStorage._();
  Set<String> _cache = {};

  Future<Set<String>> getNumbers() async {
    if(_cache.isNotEmpty){
      return _cache;
    }
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_authStatusKey) ?? <String>[];
    print("Cost");

    _cache = list.toSet();
    return _cache;
  }

  Future<void> updateNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(_authStatusKey, _cache.toList());
  }

  void addNumbers(String number){
    _cache.add(number);
    updateNumbers();
  }

  void createNumberSet(Set<String> numbers){
    _cache = numbers;
    updateNumbers();
  }

  void delNumber(String number){
    _cache.remove(number);
    updateNumbers();
  }

  bool numberPresent(String number){
    return _cache.contains(number);
  }
}