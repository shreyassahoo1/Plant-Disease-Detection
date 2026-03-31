import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // TODO: Replace with your actual Gemini API Key
  //add your api key in _apiKey variable and undo the comment
  //static const String _apiKey = '';

  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', // updated to 2.5 flash
      apiKey: _apiKey,
    );
  }

  Future<Map<String, dynamic>> analyzePlant(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart('Analyze this plant image. Identify the plant and detect any diseases. '
              'Return the result purely as a JSON object with the following structure: '
              '{ "plant_name": "Name of plant", "disease_name": "Name of disease or Healthy", '
              '"confidence": 0.95, "is_healthy": true/false, '
              '"cure_steps": ["Step 1", "Step 2", "Step 3"] } '
              'If healthy, provide care tips in cure_steps. '
              'Do not include markdown formatting like ```json ... ```, just the raw JSON string.'),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      log('Gemini Raw Response: ${response.text}');

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      // Clean up potential markdown formatting if the model strictly doesn't follow instructions
      String jsonString = response.text!.trim();
      if (jsonString.startsWith('```json')) {
        jsonString = jsonString.replaceAll('```json', '').replaceAll('```', '');
      }

      final Map<String, dynamic> result = json.decode(jsonString);
      log('Parsed JSON: $result'); // Debug log
      return result;

    } catch (e) {
      log('Error in Gemini analysis: $e');
      rethrow;
    }
  }
}
