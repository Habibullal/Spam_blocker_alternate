import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:country_picker/country_picker.dart';

import '../../models/user_request.dart';
import '../../api/firestore_service.dart';
import '../../api/device_auth_service.dart';

// Enum to manage the current step of the UI
enum AuthStep {
  enterNumber,
  verifyingNumber,
  enterDetailsAndSendOtp,
  otpSent,
  submitting,
}

class RequestAccessScreen extends StatefulWidget {
  final bool wasKickedOut;

  const RequestAccessScreen({super.key, this.wasKickedOut = false});

  @override
  State<RequestAccessScreen> createState() => _RequestAccessScreenState();
}

class _RequestAccessScreenState extends State<RequestAccessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();
  final DeviceAuthService _authService = DeviceAuthService();

  // State management variables
  AuthStep _currentStep = AuthStep.enterNumber;
  bool _isLoading = false;
  bool _requestSent = false;
  String? _verificationId;
  int? _resendToken;

  // New state variables for the updated flow
  bool _userExists = false;
  List<String> _departments = [];
  String? _selectedDepartment;

  // Country picker state
  Country _selectedCountry = Country(
    phoneCode: '91',
    countryCode: 'IN',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'India',
    example: '9123456789',
    displayName: 'India (IN) [+91]',
    displayNameNoCountryCode: 'India (IN)',
    e164Key: '91-IN-0',
  );


  @override
  void initState() {
    super.initState();
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
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }
  // --- NEW: Step 1 - Verify if the mobile number exists ---
Future<void> _checkNumberExists() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _currentStep = AuthStep.verifyingNumber;
    });

    try {
      // IMPORTANT: Replace with your actual backend URL
      final url = Uri.parse('http://172.18.224.1:3000/api/check');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'mobileNo': _mobileController.text.trim()}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final userExists = responseData['exists'] == 1;

        setState(() {
          _userExists = userExists;
          if (!userExists) {
            // If user does not exist, get the list of departments
            final List<dynamic> departmentData = responseData['departments'];
            _departments = departmentData.map((d) => d.toString()).toList();
          }
          _currentStep = AuthStep.enterDetailsAndSendOtp;
        });
      } else if (response.statusCode == 403) {
        // Specific handling for the "mobileNo not allowed" error
        _showErrorSnackbar('Mobile number not allowed');
        setState(() {
          _currentStep = AuthStep.enterNumber;
        });
      } else {
        // Handle other API errors (e.g., 400, 500)
        final errorData = json.decode(response.body);
        _showErrorSnackbar(errorData['message'] ?? 'An unknown error occurred.');
        setState(() {
          _currentStep = AuthStep.enterNumber;
        });
      }
    } catch (e) {
      debugPrint("Error checking number: $e");
      _showErrorSnackbar('Could not connect to the server. Please try again.');
       setState(() {
          _currentStep = AuthStep.enterNumber;
        });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- UPDATED: Step 2 - Send OTP ---
  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    // Use the selected country code
    final mobileNumber = '+${_selectedCountry.phoneCode}${_mobileController.text.trim()}';

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: mobileNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        setState(() { _isLoading = false; });
        _otpController.text = credential.smsCode ?? '';
        await _verifyOtpAndSubmit();
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('Verification Failed: ${e.message}');
        _showErrorSnackbar('Verification failed: ${e.message}');
        setState(() { _isLoading = false; });
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _currentStep = AuthStep.otpSent; // Move to next step
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent to your mobile number.')),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // --- UPDATED: Step 3 - Verify OTP and Submit ---
  Future<void> _verifyOtpAndSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _currentStep = AuthStep.submitting;
    });

    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );

      // Sign in to confirm the user owns the number
      await FirebaseAuth.instance.signInWithCredential(credential);
      // If successful, proceed to submit the request to Firestore
      await _submitRequest();

    } on FirebaseAuthException catch (e) {
      debugPrint('OTP Verification Failed: ${e.message}');
      _showErrorSnackbar('OTP verification failed: ${e.message}');
      // Revert step to allow re-entry of OTP
      setState(() { _currentStep = AuthStep.otpSent; });
    } finally {
      // Final loading state is handled within _submitRequest
       if (_currentStep != AuthStep.submitting) {
         setState(() { _isLoading = false; });
       }
    }
  }

  // --- UPDATED: Final Step - Submit data to Firestore ---
  Future<void> _submitRequest() async {
    final name = _nameController.text.trim();
    // Use the selected country code for the final data
    final mobile = '+${_selectedCountry.phoneCode}${_mobileController.text.trim()}';
    final deviceId = await _authService.getDeviceIdentifier();

    if (deviceId != null) {
      final userRequest = UserRequest(
        name: name,
        mobile: mobile,
        deviceId: deviceId,
        department: _userExists ? '' : _selectedDepartment!,
        timestamp: DateTime.now(),
      );

      try {
        final success = await _firestoreService.sendLoginRequest(userRequest);
        if (success) {
          setState(() {
            _requestSent = true;
          });
        } else {
          _showErrorSnackbar('Failed to submit request. Please try again.');
          setState(() { _currentStep = AuthStep.otpSent; });
        }
      } catch (e) {
        debugPrint("Error submitting request to Firestore: $e");
        _showErrorSnackbar('An error occurred. Please try again.');
        setState(() { _currentStep = AuthStep.otpSent; });
      }
    } else {
      _showErrorSnackbar('Could not retrieve device ID. Cannot submit request.');
      setState(() { _currentStep = AuthStep.otpSent; });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // --- Helper function to determine the main button's action ---
  VoidCallback? _getButtonAction() {
    if (_isLoading) return null;

    switch (_currentStep) {
      case AuthStep.enterNumber:
        return _checkNumberExists;
      case AuthStep.enterDetailsAndSendOtp:
        return _sendOtp;
      case AuthStep.otpSent:
        return _verifyOtpAndSubmit;
      default:
        return null; // Button is disabled during async operations
    }
  }

  // --- Helper function to determine the main button's text ---
  String _getButtonText() {
    switch (_currentStep) {
      case AuthStep.enterNumber:
        return 'Verify Number';
      case AuthStep.verifyingNumber:
        return 'Verifying...';
      case AuthStep.enterDetailsAndSendOtp:
        return 'Send OTP';
      case AuthStep.otpSent:
        return 'Verify & Submit';
      case AuthStep.submitting:
        return 'Submitting...';
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
              ? _buildSuccessWidget()
              : _buildFormWidget(),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildFormWidget() {
    return Form(
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

          // --- Mobile Number Field (with Country Picker) ---
          TextFormField(
            controller: _mobileController,
            readOnly: _currentStep != AuthStep.enterNumber,
            decoration: InputDecoration(
              labelText: 'Mobile Number',
              border: const OutlineInputBorder(),
              prefixIcon: Container(
                padding: const EdgeInsets.all(8.0),
                child: InkWell(
                  onTap: () {
                    if (_currentStep == AuthStep.enterNumber) {
                      showCountryPicker(
                        context: context,
                        countryListTheme: CountryListThemeData(
                          bottomSheetHeight: 500,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelect: (country) {
                          setState(() {
                            _selectedCountry = country;
                          });
                        },
                      );
                    }
                  },
                  child: Text(
                    '${_selectedCountry.flagEmoji} +${_selectedCountry.phoneCode}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              if (value!.isEmpty) return 'Please enter your mobile number';
              if (value.length != 10) return 'Mobile number must be 10 digits';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // --- Name, Department, and OTP fields (Conditionally Visible) ---
          if (_currentStep == AuthStep.enterDetailsAndSendOtp || _currentStep == AuthStep.otpSent) ...[
            // Show Name and Department only if user does NOT exist
            if (!_userExists) ...[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
                items: _departments.map((String department) {
                  return DropdownMenuItem<String>(
                    value: department,
                    child: Text(department),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedDepartment = newValue;
                  });
                },
                validator: (value) => value == null ? 'Please select a department' : null,
              ),
              const SizedBox(height: 20),
            ],

            // Show OTP field only after OTP has been sent
            if (_currentStep == AuthStep.otpSent) ...[
              TextFormField(
                controller: _otpController,
                decoration: const InputDecoration(
                  labelText: 'Enter OTP',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter the OTP';
                  if (value.length != 6) return 'OTP must be 6 digits';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  child: const Text('Resend OTP'),
                ),
              ),
            ],
          ],
          const SizedBox(height: 30),

          // --- Main Button ---
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _getButtonAction(),
                    child: Text(_getButtonText()),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSuccessWidget() {
    return Column(
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
        Text(
          'In case of any errors in the submitted information, please contact the administrator.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
