import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/alert.dart';
import 'sensor_provider.dart';

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
            id: DateTime.now().millisecondsSinceEpoch.toString() + "_m",
            title: 'Low Soil Moisture',
            message: 'Moisture level critical at ${data.moisture.toStringAsFixed(1)}%. Irrigation recommended.',
            type: 'ERROR',
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
    }
  }

  void markAsRead(String id) {
    state = state.map((a) => a.id == id ? a.copyWith(isRead: true) : a).toList();
  }
  
  void clearAll() {
    state = [];
  }
}
