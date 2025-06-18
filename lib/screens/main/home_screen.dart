import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spam_blocker/api/firestore_service.dart';
import 'package:spam_blocker/api/local_storage_service.dart';

void foo1(){
  final f = FirestoreService();
  f.fetchNumbers();
}
void foo2(){
  LocalBlockedNumbersStorage.instance.addNumbers("8284811887");
}
void foo3(){
  LocalBlockedNumbersStorage.instance.delNumber("8284811887");
}
void foo4()async {
  Set<String> ms = await LocalBlockedNumbersStorage.instance.getNumbers();
  print("$ms");
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _platform = MethodChannel('com.example.spam_blocker/channel');
  Set<String> _blockedNumbers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _platform.setMethodCallHandler(_handleNumberFetch);
    _loadBlockedNumbers();
  }

  Future<void> _loadBlockedNumbers() async {
    setState(() => _isLoading = true);
    try {
      final numbers = await LocalBlockedNumbersStorage.instance.getNumbers();
      setState(() => _blockedNumbers = numbers);
    } catch (e) {
      print("Error loading numbers: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<dynamic> _handleNumberFetch(MethodCall call) async {
    switch(call.method){
      case "checkNumber":
        final String num = call.arguments['text'] as String;
        print("number checked");
        return LocalBlockedNumbersStorage.instance.numberPresent(num);

      default:
        throw MissingPluginException('Not implemented: ${call.method}');
    }
  }

  Future<void> _removeNumber(String number) async {
    try {
      // await LocalBlockedNumbersStorage.instance.delNumber(number);
      setState(() => _blockedNumbers.remove(number));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed $number from blocked list'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove number'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _addNumber() async {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Number to Block'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'Enter phone number',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                // await LocalBlockedNumbersStorage.instance.addNumbers(controller.text);
                  setState(() => _blockedNumbers.add(controller.text));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added ${controller.text} to blocked list'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Failed to add number'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Numbers'),
        actions: [
          IconButton(
            onPressed: _loadBlockedNumbers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedNumbers.isEmpty
              ? _buildEmptyState()
              : _buildNumbersList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNumber,
        child: const Icon(Icons.add),
        tooltip: 'Add Number',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.phone_disabled,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No blocked numbers',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add numbers to block spam calls',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addNumber,
            icon: const Icon(Icons.add),
            label: const Text('Add Number'),
          ),
        ],
      ),
    );
  }

  Widget _buildNumbersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _blockedNumbers.length,
      itemBuilder: (context, index) {
        final number = _blockedNumbers.elementAt(index);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.phone_disabled,
                color: Theme.of(context).colorScheme.error,
                size: 24,
              ),
            ),
            title: Text(
              number,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              'Blocked number',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _showReportDialog(number),
                  icon: const Icon(Icons.report),
                  color: Theme.of(context).colorScheme.secondary,
                  tooltip: 'Report as spam',
                ),
                IconButton(
                  onPressed: () => _removeNumber(number),
                  icon: const Icon(Icons.delete),
                  color: Theme.of(context).colorScheme.error,
                  tooltip: 'Remove from blocked list',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReportDialog(String number) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Spam'),
        content: Text('Report $number as spam to help protect others?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Add your spam reporting logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reported $number as spam'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }
}