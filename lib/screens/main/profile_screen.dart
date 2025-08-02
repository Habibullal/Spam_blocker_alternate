import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../notifiers/theme_notifier.dart';
import '../auth/auth_wrapper.dart';
import '../../api/local_storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  String _userPhone = '';
  String _department = '';
  File? _profileImageFile;

  final TextEditingController _nameController = TextEditingController();
  final LocalAuthService _localAuthService = LocalAuthService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _localAuthService.getUserProfile();
    if (mounted) {
      setState(() {
        _userName = profile['name'] ?? 'N/A';
        _userPhone = profile['mobile'] ?? 'N/A';
        _department = profile['department'] ?? 'N/A';
        _nameController.text = _userName;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (picked != null) {
      setState(() {
        _profileImageFile = File(picked.path);
        // Here you would typically upload the image to a server
        // and save the URL, but that's beyond the current scope.
      });
    }
  }

  /// Logs the user out from Firebase and clears all local data.
  Future<void> _logout() async {
    try {
      // First, sign out from Firebase
      await FirebaseAuth.instance.signOut();
      // Then, clear all locally stored data
      await _localAuthService.clearAllData();

      if (mounted) {
        // Navigate back to the AuthWrapper, which will show the login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                backgroundImage: _profileImageFile != null ? FileImage(_profileImageFile!) : null,
                child: _profileImageFile == null
                    ? Icon(Icons.person, size: 60, color: theme.colorScheme.primary)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(_userName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(_userPhone, style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
            Text(_department, style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 24),
            Card(
              child: SwitchListTile(
                title: const Text('Dark Mode'),
                value: themeNotifier.isDarkMode,
                onChanged: (_) => themeNotifier.toggleTheme(),
                secondary: const Icon(Icons.dark_mode_outlined),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog first
                            _logout();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
