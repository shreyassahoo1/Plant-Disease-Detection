import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../data/models/rover_status.dart';
import '../data/models/history_item.dart';
import 'history_provider.dart';

final roverProvider = NotifierProvider<RoverNotifier, RoverStatus>(RoverNotifier.new);

class RoverNotifier extends Notifier<RoverStatus> {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: dotenv.env['ROVER_CONTROL_URL'] ?? 'http://172.23.128.15/',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  @override
  RoverStatus build() {
    _simulateTelemetry();
    return RoverStatus.initial();
  }

  void _simulateTelemetry() async {
    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(isConnected: true, battery: 98.0);

    // Periodic battery drain
    Stream.periodic(const Duration(seconds: 10)).listen((_) {
      if (state.isConnected) {
        final newBattery = (state.battery - 0.5).clamp(0.0, 100.0);
        state = state.copyWith(battery: newBattery);
      }
    });

    // Periodic GPS polling from http://172.23.128.15/gps
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!state.isConnected) return;
      try {
        final gpsUrl = dotenv.env['ROVER_GPS_URL'] ?? 'http://172.23.128.15/gps';
        final response = await _dio.get(gpsUrl);
        if (response.statusCode == 200 && response.data != null) {
          final Map<String, dynamic> data = response.data is String
              ? jsonDecode(response.data) as Map<String, dynamic>
              : response.data as Map<String, dynamic>;
          
          final double newLat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
          final double newLon = (data['longitude'] as num?)?.toDouble() ?? 0.0;
          
          // Only update if we get non-zero GPS coordinates
          if (newLat != 0.0 && newLon != 0.0) {
            double nextHeading = state.heading;
            
            // Check if this is the first real GPS data overriding the mock default
            final bool isFirstRealLock = (state.latitude == 12.9233643 && state.longitude == 77.5008269) &&
                ((newLat - 12.9233643).abs() > 0.005 || (newLon - 77.5008269).abs() > 0.005);
            
            List<List<double>> nextPath;
            if (isFirstRealLock) {
              nextPath = [[newLat, newLon]];
            } else {
              nextPath = List<List<double>>.from(state.path);
              
              // Calculate heading if moved significantly
              final double latDiff = newLat - state.latitude;
              final double lonDiff = newLon - state.longitude;
              if (latDiff.abs() > 0.00001 || lonDiff.abs() > 0.00001) {
                nextHeading = atan2(lonDiff, latDiff) * (180.0 / pi);
                if (nextHeading < 0) nextHeading += 360.0;
              }
              
              // Add to path if it's different from the last point
              if (nextPath.isEmpty || 
                  (nextPath.last[0] - newLat).abs() > 0.000005 || 
                  (nextPath.last[1] - newLon).abs() > 0.000005) {
                nextPath.add([newLat, newLon]);
                if (nextPath.length > 50) {
                  nextPath.removeAt(0);
                }
              }
            }

            state = state.copyWith(
              latitude: newLat,
              longitude: newLon,
              heading: nextHeading,
              path: nextPath,
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error polling rover GPS: $e');
        }
      }
    });
  }

  Future<void> move(String direction) async {
    if (!state.isConnected) return;
    
    double nextLat = state.latitude;
    double nextLon = state.longitude;
    double nextHeading = state.heading;
    const double step = 0.00004;

    switch (direction) {
      case 'FORWARD':
        final double rad = nextHeading * (pi / 180.0);
        nextLat += step * cos(rad);
        nextLon += step * sin(rad);
        break;
      case 'BACKWARD':
        final double rad = nextHeading * (pi / 180.0);
        nextLat -= step * cos(rad);
        nextLon -= step * sin(rad);
        break;
      case 'LEFT':
        nextHeading = (nextHeading - 15) % 360;
        if (nextHeading < 0) nextHeading += 360;
        break;
      case 'RIGHT':
        nextHeading = (nextHeading + 15) % 360;
        break;
    }

    final nextPath = List<List<double>>.from(state.path);
    if (direction == 'FORWARD' || direction == 'BACKWARD') {
      nextPath.add([nextLat, nextLon]);
      if (nextPath.length > 50) {
        nextPath.removeAt(0);
      }
    }

    // Update local state for UI feedback
    state = state.copyWith(
      motorStatus: 'MOVING_$direction',
      latitude: nextLat,
      longitude: nextLon,
      heading: nextHeading,
      path: nextPath,
    );
    
    // Send command to ESP32
    try {
      final path = '/${direction.toLowerCase()}';
      await _dio.get(path);
      if (kDebugMode) {
        print('Sent move command: $path');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error communicating with rover: $e');
      }
    }
  }

  Future<void> stop() async {
    if (!state.isConnected) return;
    
    state = state.copyWith(motorStatus: 'IDLE');
    
    try {
      await _dio.get('/stop');
      if (kDebugMode) {
        print('Sent stop command');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error communicating with rover: $e');
      }
    }
  }

  void setSpeed(double speed) {
    if (!state.isConnected) return;
    state = state.copyWith(speed: speed);
  }

  void toggleCamera() {
    if (!state.isConnected) return;
    state = state.copyWith(cameraActive: !state.cameraActive);
  }

  Timer? _autoPatrolTimer;

  void toggleAutoMode() {
    if (!state.isConnected) return;
    final nextAutoMode = !state.isAutoMode;
    state = state.copyWith(isAutoMode: nextAutoMode);

    if (nextAutoMode) {
      ref.read(historyProvider.notifier).addHistoryItem(HistoryItem(
        id: 'rover_patrol_start_${DateTime.now().millisecondsSinceEpoch}',
        type: 'ROVER',
        timestamp: DateTime.now(),
        title: 'Rover Auto-Patrol Started',
        description: 'Rover initiated autonomous field grid patrol.',
        severity: 'INFO',
        metadata: {
          'batteryStart': state.battery,
          'latitude': state.latitude,
          'longitude': state.longitude,
        },
      ));

      _autoPatrolTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!state.isConnected || !state.isAutoMode) {
          timer.cancel();
          _autoPatrolTimer = null;
          return;
        }

        double nextLat = state.latitude;
        double nextLon = state.longitude;
        double nextHeading = state.heading;
        const double step = 0.00003;

        final random = Random();
        if (random.nextDouble() < 0.15) {
          nextHeading = (nextHeading + (random.nextBool() ? 30 : -30)) % 360;
          if (nextHeading < 0) nextHeading += 360;
        }

        final double rad = nextHeading * (pi / 180.0);
        nextLat += step * cos(rad);
        nextLon += step * sin(rad);

        final nextPath = List<List<double>>.from(state.path);
        nextPath.add([nextLat, nextLon]);
        if (nextPath.length > 50) {
          nextPath.removeAt(0);
        }

        state = state.copyWith(
          latitude: nextLat,
          longitude: nextLon,
          heading: nextHeading,
          path: nextPath,
          motorStatus: 'MOVING_FORWARD',
        );
      });
    } else {
      _autoPatrolTimer?.cancel();
      _autoPatrolTimer = null;
      state = state.copyWith(motorStatus: 'IDLE');

      ref.read(historyProvider.notifier).addHistoryItem(HistoryItem(
        id: 'rover_patrol_stop_${DateTime.now().millisecondsSinceEpoch}',
        type: 'ROVER',
        timestamp: DateTime.now(),
        title: 'Rover Auto-Patrol Completed',
        description: 'Patrol finished successfully. Rover placed in standby.',
        severity: 'INFO',
        metadata: {
          'batteryEnd': state.battery,
          'latitude': state.latitude,
          'longitude': state.longitude,
          'pathPoints': state.path.length,
        },
      ));
    }
  }
}
