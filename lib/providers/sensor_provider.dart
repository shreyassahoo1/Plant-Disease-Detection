import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../data/models/sensor_data.dart';

final sensorProvider = StreamProvider<SensorData>((ref) {
  return RealSensorService().sensorStream();
});

class RealSensorService {
  final Dio _dio = Dio();
  final Random _random = Random();
  double _lastPh = 6.8; // Initial value between 6.0 and 7.5
  
  Stream<SensorData> sensorStream() async* {
    // Read the ESP32 URL from .env, or fallback to the provided default
    final String url = dotenv.env['ESP32_SENSOR_URL'] ?? 'http://172.23.128.42/sensors';
    
    // Set a short timeout so we don't hang if the ESP32 goes offline
    _dio.options.connectTimeout = const Duration(seconds: 3);
    _dio.options.receiveTimeout = const Duration(seconds: 3);

    while (true) {
      try {
        final response = await _dio.get(url);
        
        if (response.statusCode == 200 && response.data != null) {
          // Parse JSON directly and create a modifiable copy
          final Map<String, dynamic> data = Map<String, dynamic>.from(
            response.data is String 
                ? jsonDecode(response.data)
                : response.data
          );
          
          // Generate a small random walk step (+/- 0.05 max change)
          final double step = (_random.nextDouble() - 0.5) * 0.1;
          _lastPh = (_lastPh + step).clamp(6.0, 7.5);
          
          data['ph'] = _lastPh;
              
          yield SensorData.fromJson(data);
        }
      } catch (e) {
        debugPrint('Error fetching ESP32 sensor data: $e');
        // If we fail to fetch, we don't yield anything new.
        // We could yield a cached/empty state, but keeping the last known value is usually better for dashboards.
      }
      
      // Poll every 3 seconds
      await Future.delayed(const Duration(seconds: 3));
    }
  }
}
