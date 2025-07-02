import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/device_auth_service.dart';
import '../../notifiers/theme_notifier.dart';
import '../auth/auth_wrapper.dart';
import '../../api/local_storage_service.dart'; // Import the local storage service
import '../../api/firestore_service.dart'; // NEW: Import FirestoreService

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // User data fields
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userLocation = '';
  String _deviceId = 'Loading...'; // NEW: To store and display device ID
  String _profileImageUrl = ''; // Keep this if you plan to use it

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final LocalAuthService _localAuthService = LocalAuthService();
  final DeviceAuthService _deviceAuthService = DeviceAuthService(); // NEW: Instantiate DeviceAuthService
  final FirestoreService _firestoreService = FirestoreService(); // NEW: Instantiate FirestoreService

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    // Fetch device ID first
    final String? fetchedDeviceId = await _deviceAuthService.getDeviceIdentifier();
    if (fetchedDeviceId != null) {
      setState(() {
        _deviceId = fetchedDeviceId;
      });

      // Fetch user profile from Firestore using the device ID
      final Map<String, String> firestoreProfile =
          await _firestoreService.getUserProfileByDeviceId(fetchedDeviceId);

      // Fetch user profile from local storage (for fallback or previously saved data)
      final Map<String, String> localProfile = await _localAuthService.getUserProfile();

      setState(() {
        // Prioritize Firestore data, fallback to local storage, then default values
        _userName = firestoreProfile['name'] ?? localProfile['name'] ?? 'Unknown User';
        _userEmail = firestoreProfile['email'] ?? localProfile['email'] ?? 'No Email';
        _userPhone = firestoreProfile['mobile'] ?? localProfile['mobile'] ?? 'No Phone';
        _userLocation = firestoreProfile['location'] ?? localProfile['location'] ?? 'Unknown Location';

        _nameController.text = _userName;
        _emailController.text = _userEmail;
        _phoneController.text = _userPhone;
        _locationController.text = _userLocation;
      });
      // Save the fetched Firestore profile to local storage for future quick access
      await _localAuthService.saveUserProfile({
        'name': _userName,
        'email': _userEmail,
        'mobile': _userPhone,
        'location': _userLocation,
      });
    } else {
      // Handle case where device ID cannot be obtained
      setState(() {
        _deviceId = 'Device ID Not Available';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _editProfile() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _userName = _nameController.text;
                  _userEmail = _emailController.text;
                  _userPhone = _phoneController.text;
                  _userLocation = _locationController.text;
                });

                // Prepare data for Firestore and local storage
                final Map<String, dynamic> updatedData = {
                  'name': _userName,
                  'email': _userEmail,
                  'mobile': _userPhone, // Save as 'mobile' to match UserRequest
                  'location': _userLocation,
                };

                // Save updated profile to local storage
                await _localAuthService.saveUserProfile(Map<String, String>.from(updatedData));

                // Save updated profile to Firestore
                if (_deviceId != 'Loading...' && _deviceId != 'Device ID Not Available') {
                  try {
                    await _firestoreService.updateUserProfile(_deviceId, updatedData);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Profile updated successfully!'),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update profile in Firestore: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Cannot save profile: Device ID not available.'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final authService = DeviceAuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  backgroundImage: _profileImageUrl.isNotEmpty ? NetworkImage(_profileImageUrl) : null,
                  child: _profileImageUrl.isEmpty
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
                  child: GestureDetector(
                    onTap: () {
                      // Implement image picker here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Image picker not implemented yet.')),
                      );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(
                        Icons.camera_alt,
                        color: theme.colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _userName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _userEmail,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.phone, 'Phone Number', _userPhone),
                    const Divider(height: 24),
                    _buildDetailRow(Icons.location_on, 'Location', _userLocation),
                    const Divider(height: 24), // NEW: Divider for Device ID
                    _buildDetailRow(Icons.devices, 'Device ID', _deviceId), // NEW: Display Device ID
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.brightness_6, color: theme.colorScheme.primary),
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: themeNotifier.isDarkMode,
                onChanged: (value) {
                  themeNotifier.toggleTheme();
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _editProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Edit Profile'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: theme.colorScheme.error),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await authService.logout(); // This should clear local login status
                            await _localAuthService.clearLoginStatus(); // Ensure local storage is cleared
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const AuthWrapper()),
                              (route) => false,
                            );
                          },
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Logout'),
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
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
