import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'rover_provider.dart';
import '../data/models/weather_data.dart';

final weatherProvider = FutureProvider<WeatherData>((ref) async {
  // Watch the rover state for dynamic GPS updates
  final roverState = ref.watch(roverProvider);
  
  // Use current Rover GPS if it's set, otherwise fallback to default agricultural sector coordinates
  final double lat = roverState.latitude != 0.0 ? roverState.latitude : 12.9233643;
  final double lon = roverState.longitude != 0.0 ? roverState.longitude : 77.5008269;

  final dio = Dio();
  dio.options.connectTimeout = const Duration(seconds: 4);
  dio.options.receiveTimeout = const Duration(seconds: 4);

  try {
    final response = await dio.get(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': lat,
        'longitude': lon,
        'current': 'temperature_2m,relative_humidity_2m,weather_code',
        'daily': 'temperature_2m_max,temperature_2m_min,precipitation_probability_max',
        'timezone': 'auto',
        'forecast_days': 1
      },
    );

    if (response.statusCode == 200 && response.data != null) {
      return WeatherData.fromJson(response.data);
    } else {
      throw Exception('Failed to fetch weather data: status ${response.statusCode}');
    }
  } catch (e) {
    // Return a safe, realistic fallback weather status if offline or API is down
    return WeatherData(
      temperature: 27.5,
      humidity: 58.0,
      weatherCode: 2, // Partly cloudy
      rainProbability: 15.0,
      tempMax: 31.0,
      tempMin: 22.0,
    );
  }
});
