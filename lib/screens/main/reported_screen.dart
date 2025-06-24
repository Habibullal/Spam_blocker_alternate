import 'package:flutter/material.dart';
import '../../api/local_storage_service.dart'; // Import the local storage service

class ReportedScreen extends StatefulWidget {
  const ReportedScreen({super.key});

  @override
  State<ReportedScreen> createState() => _ReportedScreenState();
}

class _ReportedScreenState extends State<ReportedScreen> {
  List<Map<String, dynamic>> _reportedNumbers = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Reported by You']; // Removed Verified/Pending since status is hidden

  @override
  void initState() {
    super.initState();
    _loadReportedNumbers();
  }

  Future<void> _loadReportedNumbers() async {
    setState(() => _isLoading = true);
    try {
      final numbers = await LocalReportedNumbersStorage.instance.getReportedNumbers();
      setState(() {
        _reportedNumbers = numbers;
      });
    } catch (e) {
      print("Error loading reported numbers: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredNumbers {
    if (_selectedFilter == 'All') {
      return _reportedNumbers;
    } else if (_selectedFilter == 'Reported by You') {
      // Assuming 'reportedBy' field in local storage identifies 'You'
      // This will require that the 'reporterName' from profile matches 'You' or a specific ID
      // For simplicity, it filters based on the 'reportedBy' field containing "You"
      return _reportedNumbers.where((report) => report['reportedBy'].toString().toLowerCase().contains('you')).toList();
    }
    return [];
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Number: ${report['number']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Reason: ${report['reason']}'),
                const SizedBox(height: 8),
                Text('Reported By: ${report['reportedBy']}'),
                const SizedBox(height: 8),
                Text('Date: ${report['date']}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reported Numbers'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedFilter,
            onSelected: (String newValue) {
              setState(() {
                _selectedFilter = newValue;
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
            tooltip: 'Filter reports',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredNumbers.isEmpty
              ? const Center(child: Text('No reported numbers to display.'))
              : ListView.builder(
                  itemCount: _filteredNumbers.length,
                  itemBuilder: (context, index) {
                    final report = _filteredNumbers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ListTile(
                        leading: const Icon(Icons.info_outline, color: Colors.blueAccent),
                        title: Text(report['number']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report['reason'],
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'By ${report['reportedBy']} • ${report['date']}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            // Removed status display as requested
                            // const SizedBox(width: 8),
                            // Container(
                            //   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            //   decoration: BoxDecoration(
                            //     color: _getStatusColor(report['status']).withOpacity(0.1),
                            //     borderRadius: BorderRadius.circular(8),
                            //     border: Border.all(
                            //       color: _getStatusColor(report['status']).withOpacity(0.3),
                            //     ),
                            //   ),
                            //   child: Text(
                            //     report['status'],
                            //     style: TextStyle(
                            //       color: _getStatusColor(report['status']),
                            //       fontWeight: FontWeight.w500,
                            //       fontSize: 10,
                            //     ),
                            //   ),
                            // ),
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