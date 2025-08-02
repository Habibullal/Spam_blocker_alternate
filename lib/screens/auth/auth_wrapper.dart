import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:spam_blocker/api/backend_service.dart';
import 'package:spam_blocker/api/local_storage_service.dart';
import 'package:spam_blocker/api/permissions.dart';
import '../main/main_screen_container.dart';
import 'request_access_screen.dart';
import 'splash_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final BackendService _backendService = BackendService();
  final LocalAuthService _localAuthService = LocalAuthService();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  void _checkPermissions() async {
    // Use a post-frame callback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final permissionGranted = await hasPermissions();
      if (!permissionGranted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Grant Permissions"),
            content: const Text("Make this the default 'Caller ID & spam' and 'Call screening' app in your phone's settings."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Later")
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  changeDefaultApps();
                },
                child: const Text("Open Settings")
              )
            ],
          ),
        );
      }
    });
  }

  /// This function is the core of the new logic. It takes a Firebase user,
  /// gets their token, and checks their status against your backend.
  Future<int> _checkBackendStatus(User firebaseUser) async {
    try {
      final firebaseToken = await firebaseUser.getIdToken(true); // Force refresh
      if (firebaseToken == null) {
        throw Exception("Could not retrieve Firebase token.");
      }

      // This single call handles both registration and status checking
      final response = await _backendService.registerOrCheckUser(firebaseToken: firebaseToken);
      
      // Persist the new token and status
      await _localAuthService.saveAuthToken(response.token);
      await _localAuthService.saveUserType(response.userType);

      return response.userType;

    } catch (e) {
      // If anything fails, clear local data and treat as logged out
      await _localAuthService.clearAllData();
      debugPrint("Error checking backend status: $e");
      // Re-throwing will show the error in the FutureBuilder
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens to Firebase Auth state changes (login/logout)
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // While waiting for the initial auth state, show a splash screen
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // If snapshot has data, a user is logged into Firebase
        if (authSnapshot.hasData) {
          final firebaseUser = authSnapshot.data!;
          
          // Now, use a FutureBuilder to check the user's status on your backend
          return FutureBuilder<int>(
            // The key ensures the FutureBuilder re-runs if the user changes (e.g., re-login)
            key: ValueKey(firebaseUser.uid), 
            future: _checkBackendStatus(firebaseUser),
            builder: (context, statusSnapshot) {
              if (statusSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }

              if (statusSnapshot.hasError) {
                // An error occurred talking to your backend.
                // Show the login screen with a message.
                return const RequestAccessScreen(wasKickedOut: true);
              }

              if (statusSnapshot.hasData) {
                final userType = statusSnapshot.data!;
                
                switch (userType) {
                  case 2:
                    // User is approved, show the main app
                    return const MainScreenContainer();
                  case 1:
                    // User is pending approval
                    return const RequestAccessScreen(showPendingMessage: true);
                  default:
                    // User is blocked (userType 0) or has an unknown status.
                    // Treat as logged out.
                    return const RequestAccessScreen(wasKickedOut: true);
                }
              }
              
              // Default case if something unexpected happens
              return const RequestAccessScreen();
            },
          );
        }

        // If snapshot has no data, no user is logged in
        return const RequestAccessScreen();
      },
    );
  }
}
