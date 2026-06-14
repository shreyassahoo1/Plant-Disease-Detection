class DiseaseResult {
  final String diseaseName;
  final double confidence;
  final String severity; // LOW, MEDIUM, HIGH
  final List<String> precautions;
  final List<String> indianFertilizers;
  final String imagePath;
  final DateTime timestamp;

  DiseaseResult({
    required this.diseaseName,
    required this.confidence,
    required this.severity,
    required this.precautions,
    required this.indianFertilizers,
    required this.imagePath,
    required this.timestamp,
  });
}
