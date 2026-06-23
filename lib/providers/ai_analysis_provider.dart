import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../data/models/disease_result.dart';
import '../data/models/history_item.dart';
import 'history_provider.dart';

final aiAnalysisProvider = NotifierProvider<AIAnalysisNotifier, AsyncValue<DiseaseResult?>>(AIAnalysisNotifier.new);

class AIAnalysisNotifier extends Notifier<AsyncValue<DiseaseResult?>> {
  @override
  AsyncValue<DiseaseResult?> build() {
    return const AsyncValue.data(null);
  }

  Future<void> analyzeImage(String imagePath) async {
    state = const AsyncValue.loading();
    
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        throw Exception('Gemini API Key is missing or invalid. Please check your .env file.');
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final imageFile = File(imagePath);
      
      // Fallback for simulated image paths from the UI (when testing without a real camera)
      if (!await imageFile.exists()) {
        await Future.delayed(const Duration(seconds: 2));
        final result = DiseaseResult(
          diseaseName: 'Simulated Disease (No real image)',
          confidence: 99.9,
          severity: 'LOW',
          precautions: ['Please capture a real image for actual AI analysis'],
          indianFertilizers: ['None'],
          imagePath: imagePath,
          timestamp: DateTime.now(),
        );
        ref.read(historyProvider.notifier).addHistoryItem(HistoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'SCAN',
          timestamp: result.timestamp,
          title: result.diseaseName,
          description: 'AI Analysis confidence: ${result.confidence.toStringAsFixed(1)}%',
          severity: result.severity,
          metadata: {
            'diseaseName': result.diseaseName,
            'confidence': result.confidence,
            'severity': result.severity,
            'precautions': result.precautions,
            'indianFertilizers': result.indianFertilizers,
            'imagePath': result.imagePath,
          },
        ));
        state = AsyncValue.data(result);
        return;
      }

      final imageBytes = await imageFile.readAsBytes();

      final prompt = 'Analyze this plant image. Identify the plant and detect any diseases. '
          'Return the result purely as a JSON object with the following structure exactly matching this schema: '
          '{ "diseaseName": "Name of disease or Healthy", '
          '"confidence": 95.5, "severity": "LOW", "precautions": ["Step 1", "Step 2"], '
          '"indianFertilizers": ["Fertilizer 1", "Fertilizer 2"] }. '
          'Severity must be exactly one of: LOW, MEDIUM, or HIGH. '
          'If healthy, provide care tips in precautions and general fertilizers. '
          'Do not include markdown formatting like ```json ... ```, just the raw JSON string.';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      log('Gemini Raw Response: ${response.text}');

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      String jsonString = response.text!.trim();
      if (jsonString.startsWith('```json')) {
        jsonString = jsonString.replaceAll('```json', '').replaceAll('```', '').trim();
      } else if (jsonString.startsWith('```')) {
        jsonString = jsonString.replaceAll('```', '').trim();
      }

      final Map<String, dynamic> resultData = json.decode(jsonString);
      
      final result = DiseaseResult(
        diseaseName: resultData['diseaseName'] ?? 'Unknown',
        confidence: (resultData['confidence'] ?? 0.0).toDouble(),
        severity: resultData['severity'] ?? 'LOW',
        precautions: List<String>.from(resultData['precautions'] ?? []),
        indianFertilizers: List<String>.from(resultData['indianFertilizers'] ?? []),
        imagePath: imagePath,
        timestamp: DateTime.now(),
      );

      ref.read(historyProvider.notifier).addHistoryItem(HistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'SCAN',
        timestamp: result.timestamp,
        title: result.diseaseName,
        description: 'AI Analysis confidence: ${result.confidence.toStringAsFixed(1)}%',
        severity: result.severity,
        metadata: {
          'diseaseName': result.diseaseName,
          'confidence': result.confidence,
          'severity': result.severity,
          'precautions': result.precautions,
          'indianFertilizers': result.indianFertilizers,
          'imagePath': result.imagePath,
        },
      ));

      state = AsyncValue.data(result);
    } catch (e, st) {
      log('Error in AI analysis: $e');
      state = AsyncValue.error(e, st);
    }
  }
  
  void reset() {
    state = const AsyncValue.data(null);
  }
}
