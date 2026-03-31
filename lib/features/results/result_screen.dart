import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/db/database_helper.dart';
import '../../features/home/home_screen.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;
  final String diseaseName;
  final double confidence;
  final bool isHealthy;
  final List<String> cureSteps;

  const ResultScreen({
    super.key,
    required this.imagePath,
    required this.diseaseName,
    required this.confidence,
    required this.isHealthy,
    required this.cureSteps,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {

  @override
  void initState() {
    super.initState();
    _saveToHistory();
  }

  Future<void> _saveToHistory() async {
    final date = DateFormat.yMMMd().add_jm().format(DateTime.now());
    
    await DatabaseHelper.instance.create({
      'imagePath': widget.imagePath,
      'diseaseName': widget.diseaseName,
      'confidence': widget.confidence,
      'date': date,
    });
    
    // Optional: Show snackbar
    // if (mounted) {
    //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved to History")));
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result'),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.file(
              File(widget.imagePath),
              height: 300,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                   _buildResultCard(context),
                   const SizedBox(height: 32),
                   _buildActionButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    return Column(
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Icon(
                  widget.isHealthy ? Icons.check_circle : Icons.warning,
                  color: widget.isHealthy ? Colors.green : Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.diseaseName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.isHealthy ? Colors.green : Colors.red,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text("Confidence:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: widget.confidence,
                        color: widget.isHealthy ? Colors.green : Colors.red,
                        backgroundColor: Colors.grey[200],
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text("${(widget.confidence * 100).toStringAsFixed(1)}%"),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (widget.cureSteps.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Remedies / Care Tips",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.cureSteps
                    .map((step) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("• ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(step, style: const TextStyle(fontSize: 16)),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
         Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
      },
      child: const Text('Back to Home'),
    );
  }
}
