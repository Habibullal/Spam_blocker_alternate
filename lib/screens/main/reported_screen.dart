import 'package:flutter/material.dart';

class ReportedScreen extends StatelessWidget {
  const ReportedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reported'),
      ),
      body: const Center(
        child: Text(
          'Reported Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}