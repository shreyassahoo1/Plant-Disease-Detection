import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../providers/sensor_provider.dart';
import '../../../providers/rover_provider.dart';
import '../../../providers/alerts_provider.dart';
import '../../../providers/weather_provider.dart';
import '../../../data/models/weather_data.dart';
import '../../../data/models/alert.dart';
import '../../widgets/glass_card.dart';
import '../../../core/localization/translations.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorState = ref.watch(sensorProvider);
    final roverState = ref.watch(roverProvider);
    final alerts = ref.watch(alertsProvider);
    final weatherState = ref.watch(weatherProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Simulate refresh
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AgroNet AI', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Sector 4 - Active'.tr(ref), style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Stack(
                            children: [
                              const Icon(LucideIcons.bell),
                              if (alerts.any((a) => !a.isRead))
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onPressed: () {
                            _showNotificationsSheet(context, ref, alerts);
                          },
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.settings),
                          onPressed: () => context.push('/settings'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Sensor Grid
                Text('Live Telemetry'.tr(ref), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                sensorState.when(
                  data: (data) => GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      _buildDataCard(context, 'Temperature'.tr(ref), '${data.temperature.toStringAsFixed(1)}°C', LucideIcons.thermometer, Colors.orange),
                      _buildDataCard(context, 'Humidity'.tr(ref), '${data.humidity.toStringAsFixed(1)}%', LucideIcons.droplet, Colors.blue),
                      _buildDataCard(context, 'Moisture'.tr(ref), '${data.moisture.toStringAsFixed(1)}%', LucideIcons.waves, Colors.cyan),
                      _buildDataCard(context, 'Soil pH'.tr(ref), data.ph.toStringAsFixed(1), LucideIcons.flaskConical, Colors.purple),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('Error: $err'),
                ),
                
                const SizedBox(height: 24),
                _buildIrrigationAdvisory(context, ref, sensorState, weatherState),
                const SizedBox(height: 24),
                // Rover Status
                Text('Rover Status'.tr(ref), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                GlassCard(
                  onTap: () => context.go('/rover'),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: roverState.isConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(LucideIcons.bot, color: roverState.isConnected ? Colors.green : Colors.red),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text((roverState.isConnected ? 'Connected' : 'Disconnected').tr(ref), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            Text('${'Battery'.tr(ref)}: ${roverState.battery.toStringAsFixed(0)}%', style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // Quick Actions
                Text('Quick Actions'.tr(ref), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildActionChip(context, 'Smart Scan'.tr(ref), LucideIcons.scan, () => context.go('/scan')),
                      const SizedBox(width: 12),
                      _buildActionChip(context, 'Manual Control'.tr(ref), LucideIcons.joystick, () => context.go('/rover')),
                      const SizedBox(width: 12),
                      _buildActionChip(context, 'Emergency Stop'.tr(ref), LucideIcons.octagon, () {
                        ref.read(roverProvider.notifier).stop();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rover stopped.'.tr(ref))));
                      }, isDanger: true),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text(title, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, String label, IconData icon, VoidCallback onTap, {bool isDanger = false}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDanger ? Colors.red.withOpacity(0.1) : theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDanger ? Colors.red.withOpacity(0.3) : theme.colorScheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isDanger ? Colors.red : theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.bodyMedium?.copyWith(
              color: isDanger ? Colors.red : theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildIrrigationAdvisory(BuildContext context, WidgetRef ref, AsyncValue<dynamic> sensorState, AsyncValue<WeatherData> weatherState) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Smart Irrigation Advisory'.tr(ref), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        sensorState.when(
          data: (sensorData) {
            return weatherState.when(
              data: (weatherData) {
                final double moisture = sensorData.moisture;
                final double rainProb = weatherData.rainProbability;
                
                String verdict;
                String explanation;
                IconData icon;
                Color statusColor;
                
                if (moisture >= 35.0) {
                  verdict = 'Watering Not Required';
                  explanation = 'Soil moisture is optimal (${moisture.toStringAsFixed(1)}%). Environment is well-hydrated.';
                  icon = LucideIcons.checkCircle2;
                  statusColor = Colors.greenAccent;
                } else if (rainProb >= 60.0) {
                  verdict = 'Hold Irrigation (Rain Forecast)';
                  explanation = 'Soil moisture is low (${moisture.toStringAsFixed(1)}%), but there is a ${rainProb.toStringAsFixed(0)}% chance of rain. Save water and wait.';
                  icon = LucideIcons.cloudRain;
                  statusColor = Colors.orangeAccent;
                } else {
                  verdict = 'Watering Recommended';
                  explanation = 'Soil moisture is critical at ${moisture.toStringAsFixed(1)}% and no precipitation is forecast. Turn on irrigation.';
                  icon = LucideIcons.droplet;
                  statusColor = Colors.cyanAccent;
                }
                
                return GlassCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: statusColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              verdict.tr(ref), 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              explanation.tr(ref), 
                              style: const TextStyle(fontSize: 13, height: 1.4),
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Forecast: ${weatherData.description.tr(ref)} (${weatherData.temperature.toStringAsFixed(1)}°C)', 
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                Text(
                                  'Rain Prob: ${rainProb.toStringAsFixed(0)}%', 
                                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => _buildAdvisoryLoadingCard(),
              error: (err, st) => _buildAdvisoryErrorCard(err),
            );
          },
          loading: () => _buildAdvisoryLoadingCard(),
          error: (err, st) => _buildAdvisoryErrorCard(err),
        ),
      ],
    );
  }

  Widget _buildAdvisoryLoadingCard() {
    return const GlassCard(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildAdvisoryErrorCard(dynamic error) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text('Unable to load advisory: $error', style: const TextStyle(color: Colors.redAccent)),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context, WidgetRef ref, List<Alert> alerts) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentAlerts = ref.watch(alertsProvider);
            
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('System Alerts'.tr(ref), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (currentAlerts.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            ref.read(alertsProvider.notifier).clearAll();
                            setModalState(() {});
                          },
                          child: Text('Clear All'.tr(ref), style: const TextStyle(color: Colors.redAccent)),
                        ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  if (currentAlerts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Column(
                        children: [
                          const Icon(LucideIcons.bellOff, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text('No active alerts at this time.'.tr(ref), style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: currentAlerts.length,
                        itemBuilder: (context, index) {
                          final a = currentAlerts[index];
                          
                          Color iconColor;
                          IconData iconData;
                          if (a.type == 'ERROR') {
                            iconColor = Colors.redAccent;
                            iconData = LucideIcons.xCircle;
                          } else if (a.type == 'WARNING') {
                            iconColor = Colors.orangeAccent;
                            iconData = LucideIcons.alertTriangle;
                          } else {
                            iconColor = Colors.blueAccent;
                            iconData = LucideIcons.info;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: a.isRead 
                                  ? Colors.white.withOpacity(0.01) 
                                  : Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: a.isRead 
                                    ? Colors.white.withOpacity(0.05) 
                                    : iconColor.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(iconData, color: iconColor, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.title.tr(ref), 
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 14,
                                          decoration: a.isRead ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(a.message.tr(ref), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (!a.isRead)
                                  IconButton(
                                    icon: const Icon(LucideIcons.check, size: 16),
                                    onPressed: () {
                                      ref.read(alertsProvider.notifier).markAsRead(a.id);
                                      setModalState(() {});
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    tooltip: 'Mark as read'.tr(ref),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'.tr(ref)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
