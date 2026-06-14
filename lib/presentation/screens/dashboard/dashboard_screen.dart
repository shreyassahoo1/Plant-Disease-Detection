import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../providers/sensor_provider.dart';
import '../../../providers/rover_provider.dart';
import '../../../providers/alerts_provider.dart';
import '../../widgets/glass_card.dart';
import '../../../core/localization/translations.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorState = ref.watch(sensorProvider);
    final roverState = ref.watch(roverProvider);
    final alerts = ref.watch(alertsProvider);
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
                            // TODO: Open notifications sheet
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
}
