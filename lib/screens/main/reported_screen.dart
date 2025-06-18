import 'package:flutter/material.dart';

class ReportedScreen extends StatefulWidget {
  const ReportedScreen({super.key});

  @override
  State<ReportedScreen> createState() => _ReportedScreenState();
}

class _ReportedScreenState extends State<ReportedScreen> {
  // Mock reported numbers data - replace with actual data
  final List<Map<String, dynamic>> _reportedNumbers = [
    {
      'number': '+1 555 123 4567',
      'reportedBy': 'You',
      'reason': 'Telemarketing',
      'date': '2024-01-15',
      'status': 'Verified',
    },
    {
      'number': '+1 555 987 6543',
      'reportedBy': 'you',
      'reason': 'Scam',
      'date': '2024-01-14',
      'status': 'Pending',
    },
    {
      'number': '+1 555 456 7890',
      'reportedBy': 'You',
      'reason': 'Robocall',
      'date': '2024-01-13',
      'status': 'Verified',
    },
  ];

  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Verified', 'Pending', 'Reported by You'];

  List<Map<String, dynamic>> get _filteredNumbers {
    if (_selectedFilter == 'All') return _reportedNumbers;
    if (_selectedFilter == 'Reported by You') {
      return _reportedNumbers.where((item) => item['reportedBy'] == 'You').toList();
    }
    return _reportedNumbers.where((item) => item['status'] == _selectedFilter).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Verified':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getReasonIcon(String reason) {
    switch (reason) {
      case 'Telemarketing':
        return Icons.campaign;
      case 'Scam':
        return Icons.warning;
      case 'Robocall':
        return Icons.smart_toy;
      default:
        return Icons.report;
    }
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Number:', report['number']),
            const SizedBox(height: 8),
            _buildDetailRow('Reason:', report['reason']),
            const SizedBox(height: 8),
            _buildDetailRow('Reported by:', report['reportedBy']),
            const SizedBox(height: 8),
            _buildDetailRow('Date:', report['date']),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(report['status']).withOpacity(0.3)),
                  ),
                  child: Text(
                    report['status'],
                    style: TextStyle(
                      color: _getStatusColor(report['status']),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reported Numbers'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedFilter = value),
            itemBuilder: (context) => _filterOptions.map((option) {
              return PopupMenuItem<String>(
                value: option,
                child: Row(
                  children: [
                    if (_selectedFilter == option)
                      Icon(Icons.check, color: theme.colorScheme.primary, size: 16)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(option),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedFilter,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _filteredNumbers.isEmpty
          ? _buildEmptyState()
          : _buildReportsList(),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.report_off,
            size: 80,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No reported numbers',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'All' 
                ? 'No spam numbers have been reported yet'
                : 'No numbers match the selected filter',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredNumbers.length,
      itemBuilder: (context, index) {
        final report = _filteredNumbers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getStatusColor(report['status']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getReasonIcon(report['reason']),
                color: _getStatusColor(report['status']),
                size: 24,
              ),
            ),
            title: Text(
              report['number'],
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  report['reason'],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'By ${report['reportedBy']} • ${report['date']}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
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
    );
  }
}