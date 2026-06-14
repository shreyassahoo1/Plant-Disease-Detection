class SensorData {
  final double temperature;
  final double humidity;
  final double moisture;
  final double ph;
  final DateTime timestamp;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.moisture,
    required this.ph,
    required this.timestamp,
  });

  factory SensorData.empty() => SensorData(
    temperature: 0,
    humidity: 0,
    moisture: 0,
    ph: 0,
    timestamp: DateTime.now(),
  );

  factory SensorData.fromJson(Map<String, dynamic> json) {
    // 1. Soil Moisture Conversion
    // Raw ADC is usually 0-4095. Assume 4095 is completely dry air, 0 is fully submerged.
    // % Moisture = ((4095 - raw) / 4095) * 100
    double rawSoil = (json['soil'] as num?)?.toDouble() ?? 4095.0;
    double calcMoisture = ((4095.0 - rawSoil) / 4095.0) * 100.0;
    calcMoisture = calcMoisture.clamp(0.0, 100.0);

    // 2. pH Conversion
    double calcPh;
    if (json.containsKey('ph')) {
      calcPh = (json['ph'] as num).toDouble();
    } else {
      double phVoltage = (json['ph_voltage'] as num?)?.toDouble() ?? 0.0;
      calcPh = (phVoltage / 3.3) * 14.0;
    }
    calcPh = calcPh.clamp(0.0, 14.0);

    return SensorData(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      moisture: calcMoisture,
      ph: calcPh,
      timestamp: DateTime.now(),
    );
  }
}
