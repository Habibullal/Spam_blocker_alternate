// Add this at the top of the file
import 'package:flutter/material.dart';
import '../../api/device_auth_service.dart';
import '../../models/user_request.dart';

class RequestAccessScreen extends StatefulWidget {
  // Add this parameter
  final bool wasKickedOut;

  const RequestAccessScreen({super.key, this.wasKickedOut = false});

  @override
  State<RequestAccessScreen> createState() => _RequestAccessScreenState();
}

class _RequestAccessScreenState extends State<RequestAccessScreen> {
  // ... (all your existing variables _formKey, controllers, etc. remain the same) ...
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _authService = DeviceAuthService();
  bool _isLoading = false;
  bool _requestSent = false;


  @override
  void initState() {
    super.initState();
    // NEW: If the user was kicked out, show a snackbar message
    if (widget.wasKickedOut) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your device access has been revoked.'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }
  
  // ... The rest of your _submitRequest and build method can remain largely the same.
  // I'm including the full build method for clarity.
   Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final deviceId = await _authService.getDeviceIdentifier();
      if (deviceId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not get device ID. Cannot request access.")),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final request = UserRequest(
        name: _nameController.text,
        email: _emailController.text,
        mobile: _mobileController.text,
        deviceId: deviceId,
        timestamp: DateTime.now(),
      );

      final success = await _authService.requestAccess(request);

      setState(() {
        _isLoading = false;
        if (success) {
          _requestSent = true;
        }
      });

       if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request sent successfully! Please wait for approval.")),
        );
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send request. Please try again.")),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Access'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _requestSent
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                    SizedBox(height: 20),
                    Text(
                      'Request Submitted',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Your access request has been sent. You will be logged in automatically once an administrator approves it. Please restart the app later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Text(
                        'Device Not Recognized',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please fill out the form below to request access.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value!.isEmpty ? 'Please enter your email' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _mobileController,
                        decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder()),
                        keyboardType: TextInputType.phone,
                        validator: (value) => value!.isEmpty ? 'Please enter your mobile number' : null,
                      ),
                      const SizedBox(height: 30),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)
                                  )
                                ),
                                onPressed: _submitRequest,
                                child: const Text('Submit Request'),
                              ),
                          ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}