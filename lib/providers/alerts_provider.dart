import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/alert.dart';
import '../data/models/history_item.dart';
import 'sensor_provider.dart';
import 'history_provider.dart';
import 'weather_provider.dart';

final alertsProvider = NotifierProvider<AlertsNotifier, List<Alert>>(AlertsNotifier.new);

class AlertsNotifier extends Notifier<List<Alert>> {
  @override
  List<Alert> build() {
    // Listen to sensors to auto-generate alerts
    ref.listen(sensorProvider, (previous, next) {
      if (next.hasValue) {
        final data = next.value!;
        if (data.temperature > 35.0) {
          addAlert(Alert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'High Temperature Detected',
            message: 'Temperature in Sector 4 is ${data.temperature.toStringAsFixed(1)}°C. Crop heat stress risk.',
            type: 'WARNING',
            timestamp: DateTime.now(),
          ));
        }
        if (data.moisture < 30.0) {
          addAlert(Alert(
            id: '${DateTime.now().millisecondsSinceEpoch}_m',
            title: 'Low Soil Moisture',
            message: 'Moisture level critical at ${data.moisture.toStringAsFixed(1)}%. Irrigation recommended.',
            type: 'ERROR',
            timestamp: DateTime.now(),
          ));
        }
      }
    });

    // Listen to weather forecast to generate daily alerts
    ref.listen(weatherProvider, (previous, next) {
      if (next.hasValue) {
        final weather = next.value!;
        final now = DateTime.now();
        final dateKey = '${now.year}${now.month}${now.day}';

        // 1. Severe storms / thunderstorms
        if (weather.weatherCode >= 95) {
          addAlert(Alert(
            id: 'weather_storm_$dateKey',
            title: 'Severe Storm Warning',
            message: 'Thunderstorms or hail forecast today. Secure loose field objects and check crop covers.',
            type: 'ERROR',
            timestamp: DateTime.now(),
          ));
        }
        // 2. High precipitation (heavy rain) forecast
        else if (weather.rainProbability > 75.0) {
          addAlert(Alert(
            id: 'weather_rain_$dateKey',
            title: 'Heavy Rain Forecast',
            message: 'Rain probability is ${weather.rainProbability.toStringAsFixed(0)}% today. Consider pausing your irrigation schedule.',
            type: 'WARNING',
            timestamp: DateTime.now(),
          ));
        }

        // 3. Heatwave threat
        if (weather.tempMax > 38.0) {
          addAlert(Alert(
            id: 'weather_heat_$dateKey',
            title: 'Extreme Heatwave Advisory',
            message: 'Maximum temperature is forecast to reach ${weather.tempMax.toStringAsFixed(1)}°C today. Prepare soil watering.',
            type: 'WARNING',
            timestamp: DateTime.now(),
          ));
        }

        // 4. Frost warning
        if (weather.tempMin < 6.0) {
          addAlert(Alert(
            id: 'weather_frost_$dateKey',
            title: 'Critical Frost Warning',
            message: 'Night temperature forecast to plunge to ${weather.tempMin.toStringAsFixed(1)}°C. Cover cold-sensitive plants.',
            type: 'WARNING',
            timestamp: DateTime.now(),
          ));
        }
      }
    });

    return [];
  }

  void addAlert(Alert alert) {
    // Avoid spamming the same alert type repeatedly within a short timeframe
    final recentSimilar = state.where((a) => a.title == alert.title && DateTime.now().difference(a.timestamp).inMinutes < 5);
    if (recentSimilar.isEmpty) {
      state = [alert, ...state];
      ref.read(historyProvider.notifier).addHistoryItem(HistoryItem(
        id: alert.id,
        type: 'ALERT',
        timestamp: alert.timestamp,
        title: alert.title,
        description: alert.message,
        severity: alert.type == 'ERROR' ? 'HIGH' : 'MEDIUM',
        metadata: {
          'message': alert.message,
          'alertType': alert.type,
        },
      ));
    }
  }

  void markAsRead(String id) {
    state = state.map((a) => a.id == id ? a.copyWith(isRead: true) : a).toList();
  }
  
  void clearAll() {
    state = [];
  }
}
