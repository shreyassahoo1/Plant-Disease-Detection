import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../core/services/gemini_service.dart';
import '../../features/results/result_screen.dart';

class PreviewScreen extends StatefulWidget {
  final String imagePath;

  const PreviewScreen({super.key, required this.imagePath});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late String _currentImagePath;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.imagePath;
  }

  Future<void> _cropImage() async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _currentImagePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.green,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Image',
        ),
        WebUiSettings(
          context: context,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _currentImagePath = croppedFile.path;
      });
    }
  }

  Future<void> _analyzeImage(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analyzing image with AI (this may take a moment)...')),
    );

    try {
      final service = GeminiService();
      // await service.loadModel(); // Gemini doesn't need explicit loading like TFLite

      final prediction = await service.analyzePlant(File(_currentImagePath));
      // service.dispose(); // GeminiService doesn't strictly need dispose right now

      if (prediction.isEmpty) {
        throw Exception('No analysis result found');
      }

      final disease = prediction['disease_name'] as String? ?? 'Unknown';
      final plant = prediction['plant_name'] as String? ?? 'Plant';
      final label = '$plant $disease'; // Combine them
      final confidence = (prediction['confidence'] as num?)?.toDouble() ?? 0.0;
      final isHealthy = prediction['is_healthy'] as bool? ?? false;
      
      final cureSteps = (prediction['cure_steps'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [];

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            imagePath: _currentImagePath,
            diseaseName: label,
            confidence: confidence,
            isHealthy: isHealthy,
            cureSteps: cureSteps,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing image: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Image'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            onPressed: _cropImage,
            icon: const Icon(Icons.crop),
            tooltip: 'Crop Image',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Image.file(
              File(_currentImagePath),
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.refresh, color: Colors.orange),
                    label: const Text('Retake', style: TextStyle(color: Colors.orange)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _analyzeImage(context),
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Analyze'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
