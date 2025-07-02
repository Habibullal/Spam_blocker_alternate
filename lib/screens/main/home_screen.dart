import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spam_blocker/api/local_storage_service.dart';
import 'package:spam_blocker/api/firestore_service.dart';
import 'package:spam_blocker/api/device_auth_service.dart';
import 'package:spam_blocker/models/report.dart'; // Ensure this model exists and is correct
import 'package:intl/intl.dart'; // For date formatting
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for Timestamp

// Model for Call Log Entry
class CallLogEntry {
  final String number;
  final String type; // Incoming, Outgoing, Missed, Blocked
  final DateTime date;
  final int duration; // in seconds
  final String name; // Contact name

  CallLogEntry({
    required this.number,
    required this.type,
    required this.date,
    required this.duration,
    required this.name,
  });

  factory CallLogEntry.fromJson(Map<String, dynamic> json) {
    return CallLogEntry(
      number: json['number'] as String,
      type: json['type'] as String,
      date: DateTime.parse(json['date'] as String),
      duration: json['duration'] as int,
      name: json['name'] as String,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _platform = MethodChannel('com.example.spam_blocker/channel');
  Set<String> _blockedNumbers = {};
  List<CallLogEntry> _callLogs = []; // List to hold call log entries
  Set<String> _reportedNumbersLocally = {}; // To track locally reported numbers
  bool _isLoading = false;

  final TextEditingController _reportedNumberController = TextEditingController();
  final TextEditingController _reportReasonController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();
  final DeviceAuthService _deviceAuthService = DeviceAuthService();
  final LocalAuthService _localAuthService = LocalAuthService(); // Keep this for user profile and login status

  @override
  void initState() {
    super.initState();
    _platform.setMethodCallHandler(_handleNumberFetch); // Keep existing handler
    _loadBlockedNumbers();
    _loadReportedNumbersLocally(); // Load locally reported numbers
    _requestAndFetchCallLogs(); // New: Request permission and fetch call logs
  }

  @override
  void dispose() {
    _reportedNumberController.dispose();
    _reportReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadBlockedNumbers() async {
    setState(() => _isLoading = true);
    final numbers = await LocalBlockedNumbersStorage.instance.getNumbers();
    setState(() {
      _blockedNumbers = numbers;
      _isLoading = false;
    });
  }

  // New: Load locally reported numbers
  Future<void> _loadReportedNumbersLocally() async {
    final reportedList = await LocalReportedNumbersStorage.instance.getReportedNumbers();
    setState(() {
      _reportedNumbersLocally = reportedList.map((e) => e['number'] as String).toSet();
    });
  }

  // Keep this for existing call blocking services communication if needed
  Future<dynamic> _handleNumberFetch(MethodCall call) async {
    if (call.method == "callLogPermissionGranted") {
      if (call.arguments == true) {
        _fetchCallLogs();
      } else {
        _showPermissionDeniedDialog('Call Log');
      }
    }
    switch (call.method) {
      case "checkNumber":
        final String num = call.arguments['text'] as String;
        print("number checked");
        return LocalBlockedNumbersStorage.instance.numberPresent(num);
      default:
        return null;
    }
  }

  Future<void> _requestAndFetchCallLogs() async {
    try {
      await _platform.invokeMethod("requestContactPermission");
      final bool? granted = await _platform.invokeMethod('requestCallLogPermission');
      if (granted == true) {
        _fetchCallLogs();
      } else {
        // Permission not granted immediately, will be handled by onRequestPermissionsResult in MainActivity
      }
    } on PlatformException catch (e) {
      print("Failed to request call log permission: '${e.message}'.");
    }
  }

  Future<void> _fetchCallLogs() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic>? result = await _platform.invokeMethod('getCallLogs');
      if (result != null) {
        setState(() {
          _callLogs = result.map((e) => CallLogEntry.fromJson(Map<String, dynamic>.from(e))).toList();
          _isLoading = false;
        });
      }
    } on PlatformException catch (e) {
      print("Failed to get call logs: '${e.message}'.");
      setState(() => _isLoading = false);
      if (e.code == "PERMISSION_DENIED") {
        _showPermissionDeniedDialog('Call Log');
      }
    }
  }

  void _showPermissionDeniedDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$permissionType Permission Required'),
          content: Text('Please grant $permissionType permission in your device settings to use this feature.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showReportDialog([String? prefilledNumber]) async {
    if (prefilledNumber != null) {
      _reportedNumberController.text = prefilledNumber;
    } else {
      _reportedNumberController.clear();
    }
    _reportReasonController.clear();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Report a Number'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextFormField(
                  controller: _reportedNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Number to Report',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: prefilledNumber != null,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reportReasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Report',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              onPressed: () async {
                final String number = _reportedNumberController.text.trim();
                final String reason = _reportReasonController.text.trim();

                debugPrint('Report button pressed. Number: $number, Reason: $reason');

                if (number.isNotEmpty && reason.isNotEmpty) {
                  debugPrint('Number and reason are not empty. Proceeding...');
                  final String? deviceId = await _deviceAuthService.getDeviceIdentifier();
                  debugPrint('Device ID fetched: $deviceId');

                  if (deviceId != null) {
                    debugPrint('Device ID is not null. Proceeding with report.');
                    try {
                      // Fetch reporter's name and number from local profile
                      final Map<String, String> userProfile = await _localAuthService.getUserProfile();
                      final String reporterName = userProfile['name'] ?? 'Anonymous';
                      final String reporterNumber = userProfile['mobile'] ?? 'Unknown';

                      final report = Report(
                        number: number,
                        reason: reason,
                        timestamp: Timestamp.now(),
                        reporterDeviceId: deviceId,
                        reporterName: reporterName, // Add reporter name
                        reporterNumber: reporterNumber, // Add reporter number
                        status: 'pending',
                      );

                      debugPrint('Attempting to report to Firestore...');
                      await _firestoreService.reportNumber(report, number);
                      debugPrint('Reported to Firestore successfully.');

                      debugPrint('Attempting to add to local storage using toLocalJson()...');
                      await LocalReportedNumbersStorage.instance.addReportedNumber(report.toLocalJson());
                      debugPrint('Added to local storage successfully.');

                      debugPrint('Reloading locally reported numbers...');
                      await _loadReportedNumbersLocally();
                      debugPrint('Locally reported numbers reloaded.');

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Number $number reported successfully!')),
                      );
                      debugPrint('Report successful and snackbar shown.');
                    } catch (e) {
                      debugPrint('Error during reporting process: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to report number: $e')),
                      );
                    }
                  } else {
                    debugPrint('Device ID is null. Cannot report.');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error: Could not get device ID.')),
                    );
                  }
                } else {
                  debugPrint('Number or reason is empty. Showing error message.');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter both number and reason.')),
                  );
                }
              },
              child: const Text('Report'),
            ),
          ],
        );
      },
    );
  }

  // Helper to format duration
  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds s';
    } else if (seconds < 3600) {
      return '${(seconds / 60).floor()} min ${seconds % 60} s';
    } else {
      return '${(seconds / 3600).floor()} hr ${((seconds % 3600) / 60).floor()} min';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Calls'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _callLogs.isEmpty
              ? const Center(
                  child: Text('No call logs available. Ensure permissions are granted.'),
                )
              : ListView.builder(
                  itemCount: _callLogs.length,
                  itemBuilder: (context, index) {
                    final call = _callLogs[index];
                    final bool isReported = _reportedNumbersLocally.contains(call.number);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      shape: isReported
                          ? RoundedRectangleBorder(
                              side: const BorderSide(color: Colors.yellow, width: 2.0),
                              borderRadius: BorderRadius.circular(8.0),
                            )
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  call.type == 'Incoming'
                                      ? Icons.call_received
                                      : call.type == 'Outgoing'
                                          ? Icons.call_made
                                          : Icons.call_missed,
                                  color: call.type == 'Missed' ? Colors.red : Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    call.name != "Unknown" ? call.name : call.number,
                                    style: Theme.of(context).textTheme.titleMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (call.name != "Unknown")
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      call.number,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 32.0),
                              child: Text(
                                '${call.type} - ${DateFormat('MMM d, hh:mm a').format(call.date)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            if (call.type != 'Missed' && call.duration > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 32.0),
                                child: Text(
                                  'Duration: ${_formatDuration(call.duration)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _showReportDialog(call.number);
                                },
                                icon: const Icon(Icons.report),
                                label: const Text('Report'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: null,
    );
  }
}
