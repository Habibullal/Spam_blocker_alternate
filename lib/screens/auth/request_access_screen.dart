import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:country_picker/country_picker.dart';

import '../../api/backend_service.dart';
import '../../api/local_storage_service.dart';
import '../main/main_screen_container.dart'; // Import for navigation

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
  final bool showPendingMessage;

  const RequestAccessScreen({
    super.key,
    this.wasKickedOut = false,
    this.showPendingMessage = false,
  });

  @override
  State<RequestAccessScreen> createState() => _RequestAccessScreenState();
}

class _RequestAccessScreenState extends State<RequestAccessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();

  final BackendService _backendService = BackendService();
  final LocalAuthService _localAuthService = LocalAuthService();

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
        _showErrorSnackbar('Your device access has been revoked.');
      });
    }
    if (widget.showPendingMessage) {
      _requestSent = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // --- Step 1 - Verify if the mobile number exists ---
  Future<void> _checkNumberExists() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _currentStep = AuthStep.verifyingNumber;
    });

    try {
      final response = await _backendService.checkNumberExists(_mobileController.text.trim());
      setState(() {
        _userExists = response.exists;
        if (!response.exists) {
          _departments = response.departments;
        }
        _currentStep = AuthStep.enterDetailsAndSendOtp;
      });
    } catch (e) {
      _showErrorSnackbar(e.toString());
      setState(() {
        _currentStep = AuthStep.enterNumber;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Step 2 - Send OTP ---
  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

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
        _showErrorSnackbar('Verification failed: ${e.message}');
        setState(() { _isLoading = false; });
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _currentStep = AuthStep.otpSent;
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

  // --- Step 3 - Verify OTP and Register with the backend ---
  Future<void> _verifyOtpAndSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _currentStep = AuthStep.submitting;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      await _registerUserOnServer();
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar('OTP verification failed: ${e.message}');
      setState(() { _currentStep = AuthStep.otpSent; });
    } finally {
      if(mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // --- Final Step - Submit data to your backend server ---
  Future<void> _registerUserOnServer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackbar('User not authenticated. Please restart.');
      setState(() { _currentStep = AuthStep.enterNumber; });
      return;
    }

    final firebaseToken = await user.getIdToken();
    if (firebaseToken == null) {
      _showErrorSnackbar('Failed to get authentication token. Please try again.');
      setState(() { _currentStep = AuthStep.otpSent; });
      return;
    }

    try {
      final response = await _backendService.registerOrCheckUser(
        firebaseToken: firebaseToken,
        username: _userExists ? null : _nameController.text.trim(),
        department: _userExists ? null : _selectedDepartment,
      );

      // Save token and user type to local storage
      await _localAuthService.saveAuthToken(response.token);
      await _localAuthService.saveUserType(response.userType);
      
      // NEW: Handle navigation based on userType
      if (response.userType == 2) {
        // Approved user, go directly to the app
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreenContainer()),
            (route) => false,
          );
        }
      } else {
        // Pending user, show the success/pending message
        setState(() {
          _requestSent = true;
        });
      }
    } catch (e) {
      _showErrorSnackbar(e.toString());
      setState(() { _currentStep = AuthStep.otpSent; });
    }
  }

  // --- UI Helper Methods ---

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  VoidCallback? _getButtonAction() {
    if (_isLoading) return null;
    switch (_currentStep) {
      case AuthStep.enterNumber: return _checkNumberExists;
      case AuthStep.enterDetailsAndSendOtp: return _sendOtp;
      case AuthStep.otpSent: return _verifyOtpAndSubmit;
      default: return null;
    }
  }

  String _getButtonText() {
    switch (_currentStep) {
      case AuthStep.enterNumber: return 'Verify Number';
      case AuthStep.verifyingNumber: return 'Verifying...';
      case AuthStep.enterDetailsAndSendOtp: return 'Send OTP';
      case AuthStep.otpSent: return 'Verify & Submit';
      case AuthStep.submitting: return 'Submitting...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Access')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: _requestSent ? _buildSuccessWidget() : _buildFormWidget(),
        ),
      ),
    );
  }

  Widget _buildFormWidget() {
    // This widget's code is long and has no logic changes, so it's omitted for brevity.
    // The existing implementation is correct.
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

          if (_currentStep == AuthStep.enterDetailsAndSendOtp || _currentStep == AuthStep.otpSent) ...[
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
          'Your access request has been submitted!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          'Please wait for administrator approval. The app will unlock automatically once your request is reviewed.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
