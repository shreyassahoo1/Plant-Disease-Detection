import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../providers/sensor_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../data/models/history_item.dart';
import '../../../core/localization/translations.dart';
import '../../widgets/glass_card.dart';

class SensorsScreen extends ConsumerStatefulWidget {
  const SensorsScreen({super.key});

  @override
  ConsumerState<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends ConsumerState<SensorsScreen> {
  final List<FlSpot> _tempSpots = [];
  final List<FlSpot> _humiditySpots = [];
  final List<FlSpot> _moistureSpots = [];
  final List<FlSpot> _phSpots = [];
  double _timeX = 0;

  @override
  void initState() {
    super.initState();
    
    // Pre-populate initial state from current provider value if it is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sensorState = ref.read(sensorProvider);
      sensorState.whenData((data) {
        if (mounted) {
          setState(() {
            _addSensorDataPoint(data);
          });
        }
      });
    });
  }

  void _addSensorDataPoint(dynamic data) {
    _tempSpots.add(FlSpot(_timeX, data.temperature));
    _humiditySpots.add(FlSpot(_timeX, data.humidity));
    _moistureSpots.add(FlSpot(_timeX, data.moisture));
    _phSpots.add(FlSpot(_timeX, data.ph));
    _timeX += 1;

    if (_tempSpots.length > 20) _tempSpots.removeAt(0);
    if (_humiditySpots.length > 20) _humiditySpots.removeAt(0);
    if (_moistureSpots.length > 20) _moistureSpots.removeAt(0);
    if (_phSpots.length > 20) _phSpots.removeAt(0);
  }

  @override
  Widget build(BuildContext context) {
    final sensorState = ref.watch(sensorProvider);
    final theme = Theme.of(context);

    // Listen to updates from sensorProvider stream
    ref.listen<AsyncValue<dynamic>>(sensorProvider, (previous, next) {
      next.whenData((data) {
        if (mounted) {
          setState(() {
            _addSensorDataPoint(data);
          });
        }
      });
    });

    final currentTempStr = sensorState.hasValue 
        ? '${sensorState.value!.temperature.toStringAsFixed(1)}°C' 
        : '--°C';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Sensor Analytics'.tr(ref)),
        actions: [
          if (sensorState.hasValue)
            IconButton(
              icon: const Icon(LucideIcons.save),
              tooltip: 'Record Snapshot'.tr(ref),
              onPressed: () {
                final data = sensorState.value!;
                ref.read(historyProvider.notifier).addHistoryItem(
                  HistoryItem(
                    id: 'sensor_snap_${DateTime.now().millisecondsSinceEpoch}',
                    type: 'SENSOR',
                    timestamp: DateTime.now(),
                    title: 'Manual Telemetry Snapshot',
                    description: 'Logged: Temp ${data.temperature.toStringAsFixed(1)}°C, Moisture ${data.moisture.toStringAsFixed(1)}%',
                    severity: 'INFO',
                    metadata: {
                      'temperature': data.temperature,
                      'humidity': data.humidity,
                      'moisture': data.moisture,
                      'ph': data.ph,
                    },
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Telemetry snapshot saved to history!'.tr(ref)),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Real-time Temperature'.tr(ref), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  currentTempStr,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GlassCard(
              height: 250,
              padding: const EdgeInsets.all(24.0),
              child: _tempSpots.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        titlesData: const FlTitlesData(
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _tempSpots,
                            isCurved: true,
                            color: Colors.orange,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.orange.withOpacity(0.2),
                            ),
                          ),
                        ],
                        minY: 10,
                        maxY: 50,
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            Text('Other Real-time Metrics'.tr(ref), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMiniChart(
                    'Humidity', 
                    Colors.blue, 
                    _humiditySpots, 
                    sensorState.hasValue ? '${sensorState.value!.humidity.toStringAsFixed(1)}%' : '--%',
                    0,
                    100
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMiniChart(
                    'Moisture', 
                    Colors.cyan, 
                    _moistureSpots, 
                    sensorState.hasValue ? '${sensorState.value!.moisture.toStringAsFixed(1)}%' : '--%',
                    0,
                    100
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMiniChart(
              'Soil pH', 
              Colors.purpleAccent, 
              _phSpots, 
              sensorState.hasValue ? sensorState.value!.ph.toStringAsFixed(1) : '--',
              0,
              14
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChart(String title, Color color, List<FlSpot> spots, String currentVal, double minY, double maxY) {
    final theme = Theme.of(context);
    return GlassCard(
      height: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                currentVal,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: spots.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: color,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withOpacity(0.15),
                          ),
                        ),
                      ],
                      minY: minY,
                      maxY: maxY,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
