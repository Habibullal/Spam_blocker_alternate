// request_access_screen.dart
// Add this at the top of the file
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for FilteringTextInputFormatter
import '../../api/device_auth_service.dart';
import '../../models/user_request.dart';
import '../../api/firestore_service.dart'; // NEW: Import FirestoreService

class RequestAccessScreen extends StatefulWidget {
  // Add this parameter
  final bool wasKickedOut;

  const RequestAccessScreen({super.key, this.wasKickedOut = false});

  @override
  State<RequestAccessScreen> createState() => _RequestAccessScreenState();
}

class _RequestAccessScreenState extends State<RequestAccessScreen> {
  static const _channel = MethodChannel('com.example.spam_blocker/channel');
  String? _selectedNumber;
  List<Map<String, dynamic>> _sims = [];
  bool _loading = false;
  String? _error;
  bool _simPermDone = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  // Removed _emailController
  final _mobileController = TextEditingController();
  final DeviceAuthService _authService = DeviceAuthService();
  final FirestoreService _firestoreService = FirestoreService(); // NEW: Instantiate FirestoreService
  bool _isLoading = false;
  bool _requestSent = false;


  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler(_platformCallHandler);
    _requestPermissionsAndLoad();
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

  @override
  void dispose() {
    _nameController.dispose();
    // Removed _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _platformCallHandler(MethodCall call) async {
      if (call.method == 'simPermissionGranted') {
        final granted = call.arguments as bool;
        if (granted) {
          await _loadSimInfo();
        } else {
          setState(() {
            _loading = false;
            _error = 'SIM permissions were denied.';
          });
        }
      }
    }

  Future<void> _requestPermissionsAndLoad() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final already = await _channel.invokeMethod<bool>('requestSimPermission') ?? false;
      print("hello"+already.toString());
      if (already) {
        await _loadSimInfo();
        setState(() {
          _simPermDone = true;
        });
      }
      // otherwise wait for callback
    } on PlatformException catch (e) {
      setState(() {
        _loading = false;
        _error = 'Error requesting permissions: ${e.message}';
      });
    }
  }

  Future<void> _loadSimInfo() async {
    try {
      final List<dynamic>? raw =
          await _channel.invokeMethod<List<dynamic>>('getSimInfo');
      if (raw == null) throw Exception('Null response');
      // Directly cast each element to Map<String, dynamic>
      final sims = raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
      setState(() {
        _sims = sims;
        _loading = false;
      });
      print(_sims);
    } on PlatformException catch (e) {
      setState(() {
        _loading = false;
        _error = 'Error fetching SIM info: ${e.message}';
      });
    }
  }

  bool get _hasValidSimNumber {
    if (_sims.isEmpty) return false;
    final firstNumber = _sims[0]['number'];
    print(_sims);
    return firstNumber != null && firstNumber.toString().trim().isNotEmpty;
  }

  Future<void> _submitRequest() async {

    if(!_simPermDone){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Requested permissions not granted!"), duration: Duration(seconds: 2)),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final name = _nameController.text;
      final mobile = '+91${_hasValidSimNumber?_selectedNumber:_mobileController.text}'; // Auto-prefix +91

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm Request Details'),
          content: Text('Name: $name\nMobile Number: $mobile\n\nPlease verify these details before submitting.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final deviceId = await _authService.getDeviceIdentifier();

        if (deviceId != null) {
          final userRequest = UserRequest(
            name: name,
            mobile: mobile,
            deviceId: deviceId,
            timestamp: DateTime.now(),
          );

          try {
            // Use the FirestoreService to send the request
            final success = await _firestoreService.sendLoginRequest(userRequest);
            if (success) {
              setState(() {
                _requestSent = true;
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to submit request. Please try again.')),
              );
            }
          } catch (e) {
            debugPrint("Error submitting request to Firestore: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('An error occurred. Please try again.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not retrieve device ID. Cannot submit request.')),
          );
        }
      }

      setState(() {
        _isLoading = false;
      });
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
          padding: const EdgeInsets.all(16.0),
          child: _requestSent
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                    const SizedBox(height: 20),
                    Text(
                      'Your access request has been submitted successfully!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Please wait for administrator approval. You will be notified when your request is reviewed.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    // Modified success screen text
                    Text(
                      'In case of any errors in the submitted information, please contact the administrator.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Request Access',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                        validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 20),
                      
                      _hasValidSimNumber ? 
                      DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Mobile Number',
                        border: OutlineInputBorder(),
                      ),
                      items: _sims.map((sim) {
                        final num = sim['number'] as String;
                        return DropdownMenuItem(value: num, child: Text(num));
                      }).toList(),
                      value: _selectedNumber,
                      onChanged: (val) => setState(() => _selectedNumber = val),
                      validator: (value) =>
                          value == null ? 'Please select your mobile number' : null,
                      ) 
                      :TextFormField(
                        controller: _mobileController,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number',
                          border: OutlineInputBorder(),
                          prefixText: '+91 ', // Visual prefix
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly, // Only allow digits
                          LengthLimitingTextInputFormatter(10), // Limit to 10 digits
                        ],
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your mobile number';
                          }
                          if (value.length != 10) {
                            return 'Mobile number must be exactly 10 digits';
                          }
                          return null;
                        },
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