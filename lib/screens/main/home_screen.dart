import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spam_blocker/api/backend_service.dart';
import 'package:spam_blocker/api/local_storage_service.dart';
import 'package:intl/intl.dart';

// Model for Call Log Entry
class CallLogEntry {
  final String number;
  final String type;
  final DateTime date;
  final int duration;
  final String name;

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
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
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
  List<CallLogEntry> _callLogs = [];
  bool _isLoading = false;

  final TextEditingController _reportedNumberController = TextEditingController();
  final BackendService _backendService = BackendService();

  @override
  void initState() {
    super.initState();
    _requestAndFetchCallLogs();
  }

  @override
  void dispose() {
    _reportedNumberController.dispose();
    super.dispose();
  }

  Future<void> _requestAndFetchCallLogs() async {
    setState(() => _isLoading = true);
    try {
      final bool? granted = await _platform.invokeMethod('requestCallLogPermission');
      if (granted == true) {
        final List<dynamic>? result = await _platform.invokeMethod('getCallLogs');
        if (result != null) {
          setState(() {
            _callLogs = result.map((e) => CallLogEntry.fromJson(Map<String, dynamic>.from(e))).toList();
          });
        }
      } else {
        _showPermissionDeniedDialog('Call Log');
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to get call logs: '${e.message}'.");
      if (e.code == "PERMISSION_DENIED") {
        _showPermissionDeniedDialog('Call Log');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showPermissionDeniedDialog(String permissionType) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$permissionType Permission Required'),
          content: Text('Please grant $permissionType permission in settings to use this feature.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitReport(String numberToReport) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackbar("You must be logged in to report a number.");
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final firebaseToken = await user.getIdToken();
      if (firebaseToken == null) {
        throw Exception("Could not get authentication token.");
      }

      await _backendService.submitReport(
        firebaseToken: firebaseToken,
        mobileNo: numberToReport,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Number $numberToReport reported successfully!')),
        );
      }
    } catch (e) {
      _showErrorSnackbar('Failed to report number: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showReportDialog(String prefilledNumber) async {
    _reportedNumberController.text = prefilledNumber;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Report'),
          content: Text('Are you sure you want to report the number $prefilledNumber?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _submitReport(prefilledNumber);
              },
              child: const Text('Report'),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
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
                  child: Text('No call logs found.'),
                )
              : RefreshIndicator(
                  onRefresh: _requestAndFetchCallLogs,
                  child: ListView.builder(
                    itemCount: _callLogs.length,
                    itemBuilder: (context, index) {
                      final call = _callLogs[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                        child: ListTile(
                          leading: Icon(
                            call.type == 'Incoming' ? Icons.call_received
                                : call.type == 'Outgoing' ? Icons.call_made
                                : Icons.call_missed,
                            color: call.type == 'Missed' || call.type == 'Blocked' ? Colors.red : Colors.green,
                          ),
                          title: Text(call.name != "Unknown" ? call.name : call.number),
                          subtitle: Text(
                            '${call.type} at ${DateFormat.yMd().add_jm().format(call.date)}'
                            '${call.duration > 0 ? " (${_formatDuration(call.duration)})" : ""}'
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.report_problem_outlined),
                            tooltip: 'Report Number',
                            onPressed: () => _showReportDialog(call.number),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
