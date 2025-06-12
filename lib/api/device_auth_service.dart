import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:spam_blocker/api/firestore_service.dart';
import '../models/user_request.dart';
import 'local_storage_service.dart'; // <-- IMPORT THE NEW SERVICE

class DeviceAuthService {
  final firebaseDB = FirestoreService();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final LocalAuthService _localAuthService = LocalAuthService(); // <-- INSTANTIATE IT

  // Get a unique device identifier (no changes here)
  Future<String?> getDeviceIdentifier() async {
    try {
      if (kIsWeb) return null;
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor;
      }
    } catch (e) {
      debugPrint("Error getting device identifier: $e");
    }
    return null;
  }

  // Check if the device is registered in Firestore
  Future<bool> isDeviceRegistered() async {
    final deviceId = await getDeviceIdentifier();
    if (deviceId == null) return false;

    try {
      final isRegistered = await firebaseDB.isDeviceInDB(deviceId);
      await _localAuthService.saveLoginStatus(isRegistered);

      return isRegistered;
    } catch (e) {
      debugPrint("Error checking device registration online: $e");
      // In case of a network error, don't change the local status
      return await _localAuthService.isUserLoggedInLocally();
    }
  }

  // Request access function (no changes here)
  Future<bool> requestAccess(UserRequest request) async {
    try {
      firebaseDB.sendLoginRequest(request);
    } catch (e) {
      debugPrint("Error sending access request: $e");
      return false;
    }
    return true;
  }

  // *** NEW: A function specifically for logging out ***
  Future<void> logout() async {
    await _localAuthService.clearLoginStatus();
    // You could also add logic here to inform your backend that the user has logged out
  }
}