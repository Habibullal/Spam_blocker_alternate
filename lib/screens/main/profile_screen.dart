import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/device_auth_service.dart';
import '../../notifiers/theme_notifier.dart';
import '../auth/auth_wrapper.dart'; // Import to allow navigation

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate the auth service to call the logout method
    final authService = DeviceAuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Theme toggle card
            Consumer<ThemeNotifier>(
              builder: (context, themeNotifier, child) {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: SwitchListTile(
                    title: const Text('Dark Mode'),
                    value: themeNotifier.isDarkMode,
                    onChanged: (value) {
                      themeNotifier.toggleTheme();
                    },
                    secondary: Icon(
                      themeNotifier.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // NEW: Logout Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              onPressed: () async {
                // Call the logout method
                await authService.logout();
                // Navigate the user back to the AuthWrapper, which will now find them logged out
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthWrapper()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}