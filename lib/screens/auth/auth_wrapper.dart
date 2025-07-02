import 'package:flutter/material.dart';
import 'package:spam_blocker/api/permissions.dart';
import '../../api/device_auth_service.dart';
import '../../api/local_storage_service.dart';
import '../../api/firestore_service.dart'; // ADD THIS IMPORT
import '../main/main_screen_container.dart';
import 'request_access_screen.dart';
import 'splash_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final LocalAuthService _localAuth = LocalAuthService();
  final DeviceAuthService _deviceAuth = DeviceAuthService();
  final FirestoreService _firestoreService = FirestoreService(); // ADD THIS

  late Future<bool> _isLoggedInLocally, permissionGranted;

  @override
  void initState() {
    super.initState();
    // On start, just check the local device storage
    _isLoggedInLocally = _localAuth.isUserLoggedInLocally();
    checkPermissions();
  }

  void checkPermissions() async {
    final permissionGranted = await hasPermissions();
    if(!permissionGranted){
      showDialog(
        context: context, 
        builder: (ctx) => AlertDialog(
          title: const Text("Grant Permissions"),
          content: const Text("Make the App default for 'Caller ID and spam App' and 'Call Redirecting App'"),
          actions: [
            OutlinedButton(onPressed: (){
              Navigator.of(ctx).pop();
            }, 
              child: const Text("Deny")
            ),

            OutlinedButton(onPressed: (){
              Navigator.of(ctx).pop();
              changeDefaultApps();
            }, 
              child: const Text("Accept")
            )
          ],
        )
      );
    }
  }

  // NEW: Function to fetch and save user profile from Firestore
  Future<void> _fetchAndSaveUserProfile() async {
    try {
      final deviceId = await _deviceAuth.getDeviceIdentifier();
      if (deviceId != null) {
        final profile = await _firestoreService.getUserProfileByDeviceId(deviceId);
        if (profile.isNotEmpty) {
          await _localAuth.saveUserProfile(profile);
          debugPrint("User profile fetched and saved locally");
        }
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
    }
  }

  // This function performs the background check and handles navigation if access is revoked
  void _validateOnlineAndNavigate() {
    _deviceAuth.isDeviceRegistered().then((isStillRegistered) {
      if (!isStillRegistered && mounted) {
        // If the user's access was revoked, force them out
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RequestAccessScreen(wasKickedOut: true)),
          (route) => false,
        ); 
      }
      // If still registered, fetch and update profile
      _fetchAndSaveUserProfile(); // ADD THIS LINE
    }).catchError((_) {
      // Silently fail if offline. The user can continue using the app.
      debugPrint("Background validation failed. User is likely offline.");
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedInLocally,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While checking local storage, show a splash screen
          return const SplashScreen();
        }

        if (snapshot.data == true) {
          // 1. User IS logged in locally (fast path)
          // Perform a silent background check to ensure access wasn't revoked
          _validateOnlineAndNavigate();
          checkPermissions();
          // Immediately let the user into the app
          return const MainScreenContainer();
        } else {
          // 2. User is NOT logged in locally
          // Perform a full online check
          return FutureBuilder<bool>(
            future: _deviceAuth.isDeviceRegistered(),
            builder: (context, onlineSnapshot) {
              if (onlineSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }
              if (onlineSnapshot.data == true) {
                // Device is authorized online, fetch profile and let them in
                _fetchAndSaveUserProfile(); // ADD THIS LINE
                return const MainScreenContainer();
              } else {
                // Device is not authorized, show the request form
                return const RequestAccessScreen();
              }
            },
          );
        }
      },
    );
  }
}