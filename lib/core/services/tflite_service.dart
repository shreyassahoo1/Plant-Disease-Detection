import 'dart:io';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TFLiteService {
  Interpreter? _interpreter;
  List<String>? _labels;

  static const String _modelPath = 'assets/models/plant_disease_model.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(_modelPath);
      log('Model loaded successfully');
      
      final labelData = await rootBundle.loadString(_labelsPath);
      _labels = labelData.split('\n').where((s) => s.isNotEmpty).toList();
      log('Labels loaded: ${_labels?.length}');
    } catch (e) {
      log('Error loading model or labels: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> predict(File imageFile) async {
    if (_interpreter == null) {
      throw Exception('Interpreter not initialized');
    }
    if (_labels == null) {
      throw Exception('Labels not loaded');
    }

    // 1. Preprocess image
    final input = _preprocessImage(imageFile);

    // 2. Prepare output buffer
    // Output shape [1, 38] -> List of 38 doubles
    // We can just use a List<double> or List<List<double>> depending on model output
    // Usually logic returns [1, num_classes]
    final output = List.filled(1 * _labels!.length, 0.0).reshape([1, _labels!.length]);

    // 3. Run inference
    _interpreter!.run(input, output);

    // 4. Process output
    final result = _postProcessOutput(output[0]);
    
    return result;
  }

  List<List<List<List<double>>>> _preprocessImage(File imageFile) {
    // Read image
    final rawBytes = imageFile.readAsBytesSync();
    final image = img.decodeImage(rawBytes);
    
    if (image == null) throw Exception('Failed to decode image');

    // Resize to 224x224 (Standard for many models, verification needed if fails)
    final resized = img.copyResize(image, width: 224, height: 224);

    // Convert to [1, 224, 224, 3] float32 normalized [0, 1]
    // Note: Depends on model training (some need 0-1, some -1 to 1, some 0-255)
    // trying 0-1 first as it's common for TFLite converted models.
    
    // Convert to [1, 224, 224, 3] float32
    // Changing normalization from [0, 1] to [-1, 1] which is more common for MobileNet/Inception
    // Formula: (pixel - 127.5) / 127.5
    
    final input = List.generate(1, (i) => 
      List.generate(224, (y) => 
        List.generate(224, (x) {
          final pixel = resized.getPixel(x, y);
          return [
            (pixel.r - 127.5) / 127.5,
            (pixel.g - 127.5) / 127.5,
            (pixel.b - 127.5) / 127.5,
          ];
        })
      )
    );

    return input;
  }

  List<Map<String, dynamic>> _postProcessOutput(List<double> output) {
    // Basic softmax or finding max
    // Since this is classification, we map valid indices to labels
    
    final results = <Map<String, dynamic>>[];
    
    for (var i = 0; i < output.length; i++) {
      if (i < _labels!.length) {
        results.add({
          'label': _labels![i],
          'confidence': output[i],
        });
      }
    }

    // Sort by confidence descending
    results.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));

    return results;
  }

  void dispose() {
    _interpreter?.close();
  }
}
