// reported_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import for Timestamp
import '../../api/local_storage_service.dart'; // Import the local storage service
import '../../api/firestore_service.dart'; // NEW: Import FirestoreService

class ReportedScreen extends StatefulWidget {
  const ReportedScreen({super.key});

  @override
  State<ReportedScreen> createState() => _ReportedScreenState();
}

class _ReportedScreenState extends State<ReportedScreen> {
  List<Map<String, dynamic>> _reportedNumbers = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  // Updated filter options
  final List<String> _filterOptions = ['All', 'Pending', 'Blocked', 'Rejected'];
  final FirestoreService _firestoreService = FirestoreService(); // NEW: Instantiate FirestoreService


  @override
  void initState() {
    super.initState();
    _loadReportedNumbers();
  }

  Future<void> _loadReportedNumbers() async {
    setState(() => _isLoading = true);
    try {
      final numbers = await LocalReportedNumbersStorage.instance.getReportedNumbers();
      List<Map<String, dynamic>> numbersWithStatus = [];

      for (var report in numbers) {
        final phoneNumber = report['number'] as String;
        // Determine status from Firestore
        final status = await _firestoreService.getReportStatus(phoneNumber);
        numbersWithStatus.add({...report, 'status': status});
      }

      setState(() {
        _reportedNumbers = numbersWithStatus;
      });
    } catch (e) {
      debugPrint("Error loading reported numbers: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reported numbers: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredNumbers {
    if (_selectedFilter == 'All') {
      return _reportedNumbers;
    } else {
      // Filter based on the determined status
      return _reportedNumbers.where((report) => report['status'] == _selectedFilter).toList();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Blocked':
        return Colors.red;
      case 'Rejected':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  // Helper method to convert timestamp to DateTime
  DateTime _getDateTimeFromTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is DateTime) {
      return timestamp;
    } else {
      // Fallback to current time if timestamp format is unexpected
      debugPrint("Unexpected timestamp format: $timestamp");
      return DateTime.now();
    }
  }

  // NEW: Function to clear all locally saved reports
  Future<void> _clearReportHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all locally saved reported numbers? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await LocalReportedNumbersStorage.instance.clearReportedNumbers();
        await _loadReportedNumbers(); // Reload to reflect empty history
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report history cleared!')),
          );
        }
      } catch (e) {
        debugPrint("Error clearing reported numbers: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to clear history: $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Details'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Number: ${report['number']}'),
              Text('Reason: ${report['reason']}'),
              Text('Status: ${report['status']}'), // Display status
              Text('Reported By: ${report['reporterName']}'), // Display reporter name
              Text('Reporter Number: ${report['reporterNumber']}'), // Display reporter number
              Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(
                _getDateTimeFromTimestamp(report['timestamp']),
              )}'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reported Numbers'),
        actions: [
          // NEW: Filter UI
          PopupMenuButton<String>(
            onSelected: (String result) {
              setState(() {
                _selectedFilter = result;
              });
            },
            itemBuilder: (BuildContext context) {
              return _filterOptions.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Reports',
          ),
          // NEW: Clear History Button
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear History',
            onPressed: _clearReportHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredNumbers.isEmpty
              ? Center(
                  child: Text(
                    _selectedFilter == 'All'
                        ? 'No reported numbers found.'
                        : 'No ${_selectedFilter.toLowerCase()} numbers found.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredNumbers.length,
                  itemBuilder: (context, index) {
                    final report = _filteredNumbers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        title: Text(
                          report['number'],
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reason: ${report['reason']}'),
                            Text(
                              'Reported: ${DateFormat('yyyy-MM-dd HH:mm').format(
                                _getDateTimeFromTimestamp(report['timestamp']),
                              )}',
                            ),
                            const SizedBox(height: 4),
                            // NEW: Display status
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(report['status']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getStatusColor(report['status']).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                report['status'],
                                style: TextStyle(
                                  color: _getStatusColor(report['status']),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          onPressed: () => _showReportDetails(report),
                          icon: const Icon(Icons.info_outline),
                          tooltip: 'View details',
                        ),
                        onTap: () => _showReportDetails(report),
                      ),
                    );
                  },
                ),
    );
  }
}