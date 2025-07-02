// profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../api/device_auth_service.dart';
import '../../notifiers/theme_notifier.dart';
import '../auth/auth_wrapper.dart';
import '../../api/local_storage_service.dart';
import '../../api/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // User data fields
  String _userName = '';
  String _userPhone = '';
  String _deviceId = 'Loading...';
  File? _profileImageFile;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final LocalAuthService _localAuthService = LocalAuthService();
  final DeviceAuthService _deviceAuthService = DeviceAuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadDeviceId();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _localAuthService.getUserProfile();
    setState(() {
      _userName = profile['name'] ?? 'Not Set';
      _userPhone = profile['mobile'] ?? 'Not Set';
      _nameController.text = _userName;
      _phoneController.text = _userPhone;
      // TODO: load saved image path if stored locally
    });
  }

  Future<void> _loadDeviceId() async {
    final deviceId = await _deviceAuthService.getDeviceIdentifier();
    setState(() {
      _deviceId = deviceId ?? 'Could not retrieve ID';
    });
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
    );
    if (picked != null) {
      setState(() {
        _profileImageFile = File(picked.path);
      });
      // Optionally: upload to server/Firestore or save locally
    }
  }

  Future<void> _updateProfile() async {
    try {
      final updatedProfile = {
        'name': _nameController.text,
        'mobile': _phoneController.text,
      };

      await _localAuthService.saveUserProfile(updatedProfile);

      final deviceId = await _deviceAuthService.getDeviceIdentifier();
      if (deviceId != null) {
        await _firestoreService.updateUserProfile(deviceId, updatedProfile);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      _loadUserProfile();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: \$e')),
      );
    }
  }

  Future<void> _logout() async {
    final deviceId = await _deviceAuthService.getDeviceIdentifier();
    await _localAuthService.clearLoginStatus();
    if (deviceId != null) {
      try {
        await _firestoreService
            .deleteDeviceAndDecrementAuthenticatedCounter(deviceId);
      } catch (e) {
        debugPrint('Logout cleanup error: \$e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Logout successful, but failed online cleanup: \$e')),
        );
      }
    }
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor:
                          theme.colorScheme.primary.withOpacity(0.1),
                      backgroundImage: _profileImageFile != null
                          ? FileImage(_profileImageFile!) as ImageProvider
                          : null,
                      child: _profileImageFile == null
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primary,
                        child: Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Profile Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Divider(height: 24),
            _buildDetailRow(Icons.account_circle, 'Name', _userName),
            _buildDetailRow(Icons.phone, 'Mobile', _userPhone),
            _buildDetailRow(Icons.phone_android, 'Device ID', _deviceId),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Edit Profile'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Name'),
                          ),
                          TextField(
                            controller: _phoneController,
                            decoration:
                                const InputDecoration(labelText: 'Mobile Number'),
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () {
                            _updateProfile();
                            Navigator.of(context).pop();
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Dark Mode', style: theme.textTheme.titleMedium),
                Switch(
                  value: themeNotifier.isDarkMode,
                  onChanged: (_) => themeNotifier.toggleTheme(),
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
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
                          onPressed: () => _logout(),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    )),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
