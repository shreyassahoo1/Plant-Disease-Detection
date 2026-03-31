import 'dart:math';

class DiseaseService {
  static final List<Map<String, dynamic>> _mockDiseases = [
    {'name': 'Tomato Early Blight', 'confidence': 0.98, 'isHealthy': false},
    {'name': 'Tomato Late Blight', 'confidence': 0.85, 'isHealthy': false},
    {'name': 'Healthy', 'confidence': 0.99, 'isHealthy': true},
    {'name': 'Leaf Mold', 'confidence': 0.75, 'isHealthy': false},
  ];

  Future<Map<String, dynamic>> analyzeImage(String imagePath) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Pick a random result
    final random = Random();
    return _mockDiseases[random.nextInt(_mockDiseases.length)];
  }
}
