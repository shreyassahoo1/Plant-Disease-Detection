import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../data/models/history_item.dart';

final historyProvider = NotifierProvider<HistoryNotifier, List<HistoryItem>>(HistoryNotifier.new);

class HistoryNotifier extends Notifier<List<HistoryItem>> {
  late final Box _box;

  @override
  List<HistoryItem> build() {
    _box = Hive.box('historyBox');
    
    // Seed initial history if empty
    if (_box.isEmpty) {
      _seedHistory();
    }

    return _loadHistory();
  }

  List<HistoryItem> _loadHistory() {
    final List<HistoryItem> items = [];
    for (var key in _box.keys) {
      final val = _box.get(key);
      if (val == null) continue;
      try {
        if (val is String) {
          items.add(HistoryItem.fromJson(jsonDecode(val)));
        } else if (val is Map) {
          items.add(HistoryItem.fromJson(Map<String, dynamic>.from(val)));
        }
      } catch (e) {
        // Skip malformed entries
      }
    }
    // Sort descending by timestamp (newest first)
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  void _seedHistory() {
    final now = DateTime.now();
    final List<HistoryItem> seedItems = [
      HistoryItem(
        id: 'seed_1',
        type: 'SCAN',
        timestamp: now.subtract(const Duration(hours: 2)),
        title: 'Tomato Late Blight Detected',
        description: 'AI Analysis confidence: 94.5%',
        severity: 'HIGH',
        metadata: {
          'diseaseName': 'Tomato Late Blight',
          'confidence': 94.5,
          'severity': 'HIGH',
          'precautions': [
            'Isolate the affected tomato plants immediately',
            'Remove infected foliage and dispose of it far from the field',
            'Apply copper-based fungicide to healthy surrounding foliage',
            'Avoid overhead irrigation to minimize leaf moisture duration'
          ],
          'indianFertilizers': [
            'Copper Oxychloride (Fytolan)',
            'Bordeaux Mixture spray',
            'Trichoderma viride bio-fungicide'
          ],
          'imagePath': 'simulated_tomato_blight'
        },
      ),
      HistoryItem(
        id: 'seed_2',
        type: 'ALERT',
        timestamp: now.subtract(const Duration(hours: 5)),
        title: 'High Temperature Detected',
        description: 'Temperature in Sector 4 is 36.2°C. Crop heat stress risk.',
        severity: 'MEDIUM',
        metadata: {
          'message': 'Temperature in Sector 4 is 36.2°C. Crop heat stress risk.',
          'alertType': 'WARNING'
        },
      ),
      HistoryItem(
        id: 'seed_3',
        type: 'ROVER',
        timestamp: now.subtract(const Duration(days: 1)),
        title: 'Rover Auto-Patrol Completed',
        description: 'Completed automated sweep of Sector 4. No navigation anomalies.',
        severity: 'INFO',
        metadata: {
          'batteryStart': 98.0,
          'batteryEnd': 92.5,
          'durationSeconds': 450,
          'pathPointsCount': 35
        },
      ),
      HistoryItem(
        id: 'seed_4',
        type: 'SCAN',
        timestamp: now.subtract(const Duration(days: 2)),
        title: 'Healthy Wheat Crop Scanned',
        description: 'AI Analysis confidence: 98.2%',
        severity: 'LOW',
        metadata: {
          'diseaseName': 'Healthy Wheat Crop',
          'confidence': 98.2,
          'severity': 'LOW',
          'precautions': [
            'Maintain the current nitrogen enrichment schedule',
            'Check soil pH level weekly to ensure it stays between 6.0 and 7.0',
            'Monitor for early warning signs of yellow rust on lower leaves'
          ],
          'indianFertilizers': [
            'Urea (46% N)',
            'Single Super Phosphate (SSP)'
          ],
          'imagePath': 'simulated_wheat_healthy'
        },
      ),
      HistoryItem(
        id: 'seed_5',
        type: 'SENSOR',
        timestamp: now.subtract(const Duration(days: 3)),
        title: 'Manual Telemetry Snapshot',
        description: 'Soil moisture dry. Irrigation needed.',
        severity: 'LOW',
        metadata: {
          'temperature': 31.4,
          'humidity': 48.2,
          'moisture': 28.5,
          'ph': 6.3
        },
      ),
      HistoryItem(
        id: 'seed_6',
        type: 'SENSOR',
        timestamp: now.subtract(const Duration(days: 4)),
        title: 'Manual Telemetry Snapshot',
        description: 'Optimal parameters observed.',
        severity: 'LOW',
        metadata: {
          'temperature': 26.5,
          'humidity': 58.1,
          'moisture': 52.4,
          'ph': 6.8
        },
      ),
    ];

    for (var item in seedItems) {
      _box.put(item.id, jsonEncode(item.toJson()));
    }
  }

  void addHistoryItem(HistoryItem item) {
    _box.put(item.id, jsonEncode(item.toJson()));
    state = [item, ...state];
  }

  void deleteHistoryItem(String id) {
    _box.delete(id);
    state = state.where((item) => item.id != id).toList();
  }

  void clearHistory() {
    _box.clear();
    state = [];
  }
}
