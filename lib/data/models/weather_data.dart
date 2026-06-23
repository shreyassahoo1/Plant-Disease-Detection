class WeatherData {
  final double temperature;
  final double humidity;
  final int weatherCode;
  final double rainProbability;
  final double tempMax;
  final double tempMin;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.weatherCode,
    required this.rainProbability,
    required this.tempMax,
    required this.tempMin,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    // Current weather
    final current = json['current'] ?? json['current_weather'] ?? {};
    final double temp = (current['temperature_2m'] ?? current['temperature'] ?? 0.0).toDouble();
    final double hum = (current['relative_humidity_2m'] ?? current['humidity'] ?? 0.0).toDouble();
    final int code = (current['weather_code'] ?? current['weathercode'] ?? 0).toInt();

    // Daily metrics
    final daily = json['daily'] ?? {};
    final List<dynamic> tempMaxList = daily['temperature_2m_max'] ?? [];
    final List<dynamic> tempMinList = daily['temperature_2m_min'] ?? [];
    final List<dynamic> rainProbList = daily['precipitation_probability_max'] ?? [];

    final double tMax = tempMaxList.isNotEmpty ? (tempMaxList[0] as num).toDouble() : temp;
    final double tMin = tempMinList.isNotEmpty ? (tempMinList[0] as num).toDouble() : temp;
    final double rProb = rainProbList.isNotEmpty ? (rainProbList[0] as num).toDouble() : 0.0;

    return WeatherData(
      temperature: temp,
      humidity: hum,
      weatherCode: code,
      rainProbability: rProb,
      tempMax: tMax,
      tempMin: tMin,
    );
  }

  String get description {
    if (weatherCode == 0) return 'Clear Sky';
    if (weatherCode >= 1 && weatherCode <= 3) return 'Partly Cloudy';
    if (weatherCode == 45 || weatherCode == 48) return 'Foggy';
    if (weatherCode >= 51 && weatherCode <= 57) return 'Drizzle';
    if (weatherCode >= 61 && weatherCode <= 67) return 'Rainy';
    if (weatherCode >= 80 && weatherCode <= 82) return 'Rain Showers';
    if (weatherCode >= 71 && weatherCode <= 77) return 'Snowy';
    if (weatherCode >= 85 && weatherCode <= 86) return 'Snow Showers';
    if (weatherCode >= 95) return 'Thunderstorms';
    return 'Cloudy';
  }

  bool get willRain => rainProbability >= 60 || weatherCode >= 51;
}
