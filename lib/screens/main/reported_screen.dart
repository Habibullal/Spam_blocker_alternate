import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spam_blocker/api/local_storage_service.dart';
import '../../api/backend_service.dart';

class ReportedScreen extends StatefulWidget {
  const ReportedScreen({super.key});

  @override
  State<ReportedScreen> createState() => _ReportedScreenState();
}

class _ReportedScreenState extends State<ReportedScreen> {
  List<Report> _reportedNumbers = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Pending', 'Accepted', 'Rejected'];
  final BackendService _backendService = BackendService();

  @override
  void initState() {
    super.initState();
    _loadReportedNumbers();
  }

  Future<void> _loadReportedNumbers() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError("User not logged in.");
      setState(() => _isLoading = false);
      return;
    }

    try {
      final firebaseToken = await LocalAuthService().getAuthToken();
      if (firebaseToken == null) {
        throw Exception("Could not get auth token.");
      }
      final numbers = await _backendService.getReports(firebaseToken: firebaseToken);
      if (mounted) {
        setState(() {
          _reportedNumbers = numbers;
        });
      }
    } catch (e) {
      _showError("Error loading reports: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0: return 'Rejected';
      case 1: return 'Pending';
      case 2: return 'Accepted';
      default: return 'Unknown';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0: return Colors.grey;
      case 1: return Colors.orange;
      case 2: return Colors.green;
      default: return Colors.blueGrey;
    }
  }

  List<Report> get _filteredNumbers {
    if (_selectedFilter == 'All') {
      return _reportedNumbers;
    }
    final statusMap = {
      'Rejected': 0,
      'Pending': 1,
      'Accepted': 2,
    };
    return _reportedNumbers.where((report) => report.status == statusMap[_selectedFilter]).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) => setState(() => _selectedFilter = result),
            itemBuilder: (BuildContext context) =>
                _filterOptions.map((String choice) {
              return PopupMenuItem<String>(value: choice, child: Text(choice));
            }).toList(),
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Reports',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReportedNumbers,
              child: _filteredNumbers.isEmpty
                  ? Center(
                      child: Text(
                        _selectedFilter == 'All'
                            ? 'You have not reported any numbers.'
                            : 'No $_selectedFilter reports found.',
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
                              report.mobileNumber,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(report.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatusColor(report.status).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                _getStatusText(report.status),
                                style: TextStyle(
                                  color: _getStatusColor(report.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
