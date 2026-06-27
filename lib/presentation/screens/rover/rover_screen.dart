import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../providers/rover_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/esp32_cam_viewer.dart';
import '../../widgets/tactical_map.dart';
import '../../../core/localization/translations.dart';
import 'dart:math';


class RoverScreen extends ConsumerStatefulWidget {
  const RoverScreen({super.key});

  @override
  ConsumerState<RoverScreen> createState() => _RoverScreenState();
}

class _RoverScreenState extends ConsumerState<RoverScreen> {
  bool _useJoystick = false;
  Offset _joystickOffset = Offset.zero;
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    final roverState = ref.watch(roverProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Rover Control'.tr(ref)),
        actions: [
          Row(
            children: [
              Text('Buttons'.tr(ref), style: theme.textTheme.bodySmall),
              Switch(
                value: _useJoystick,
                onChanged: (val) => setState(() => _useJoystick = val),
              ),
              Text('Joystick'.tr(ref), style: theme.textTheme.bodySmall),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Camera/Map Toggle
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(LucideIcons.camera),
                  label: Text('Camera Feed'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(LucideIcons.map),
                  label: Text('Tactical Map'),
                ),
              ],
              selected: {_showMap},
              onSelectionChanged: (val) => setState(() => _showMap = val.first),
            ),
            const SizedBox(height: 16),

            // Camera Stream / Tactical Map Container
            GlassCard(
              padding: EdgeInsets.zero,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _showMap
                    ? TacticalMap(
                        latitude: roverState.latitude,
                        longitude: roverState.longitude,
                        heading: roverState.heading,
                        path: roverState.path,
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: Colors.black87,
                            child: roverState.cameraActive 
                              ? ESP32CamViewer(
                                  streamUrl: dotenv.env['ROVER_ESP32_CAM_STREAM_URL'] ?? 'http://172.20.10.7:81/stream',
                                )
                              : const Center(child: Icon(LucideIcons.cameraOff, size: 48, color: Colors.white54)),
                          ),
                          if (roverState.cameraActive)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                child: const Text('REC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Controls & Telemetry
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    child: Column(
                      children: [
                        Text('Battery'.tr(ref), style: theme.textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(roverState.battery > 20 ? LucideIcons.batteryFull : LucideIcons.batteryWarning, 
                              color: roverState.battery > 20 ? Colors.green : Colors.red),
                            const SizedBox(width: 8),
                            Text('${roverState.battery.toStringAsFixed(0)}%', style: theme.textTheme.titleMedium),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GlassCard(
                    child: Column(
                      children: [
                        Text('Status'.tr(ref), style: theme.textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Text(roverState.motorStatus.tr(ref), style: theme.textTheme.titleMedium?.copyWith(
                          color: roverState.motorStatus == 'IDLE' ? Colors.grey : theme.colorScheme.primary,
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => ref.read(roverProvider.notifier).toggleCamera(),
                  icon: Icon(roverState.cameraActive ? LucideIcons.cameraOff : LucideIcons.camera),
                  label: Text((roverState.cameraActive ? 'Stop Cam' : 'Start Cam').tr(ref)),
                ),
                ElevatedButton.icon(
                  onPressed: () => ref.read(roverProvider.notifier).toggleAutoMode(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: roverState.isAutoMode ? theme.colorScheme.primary : theme.colorScheme.surface,
                    foregroundColor: roverState.isAutoMode ? Colors.white : theme.textTheme.bodyLarge?.color,
                  ),
                  icon: const Icon(LucideIcons.bot),
                  label: Text((roverState.isAutoMode ? 'Auto: ON' : 'Auto: OFF').tr(ref)),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // D-Pad or Joystick
            Center(
              child: _useJoystick ? _buildJoystick() : _buildDPad(),
            ),
            
            const SizedBox(height: 32),
            // Speed Slider
            Text('${'Speed'.tr(ref)}: ${roverState.speed.toStringAsFixed(0)}%', textAlign: TextAlign.center),
            Slider(
              value: roverState.speed,
              min: 0,
              max: 100,
              divisions: 10,
              label: roverState.speed.round().toString(),
              onChanged: (val) => ref.read(roverProvider.notifier).setSpeed(val),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDPad() {
    return Column(
      children: [
        _buildControlButton(LucideIcons.chevronUp, () => ref.read(roverProvider.notifier).move('FORWARD')),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton(LucideIcons.chevronLeft, () => ref.read(roverProvider.notifier).move('LEFT')),
            const SizedBox(width: 16),
            _buildControlButton(LucideIcons.octagon, () => ref.read(roverProvider.notifier).stop(), isDanger: true),
            const SizedBox(width: 16),
            _buildControlButton(LucideIcons.chevronRight, () => ref.read(roverProvider.notifier).move('RIGHT')),
          ],
        ),
        _buildControlButton(LucideIcons.chevronDown, () => ref.read(roverProvider.notifier).move('BACKWARD')),
      ],
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed, {bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Listener(
        onPointerDown: (_) => onPressed(),
        onPointerUp: (_) { if (!isDanger) ref.read(roverProvider.notifier).stop(); },
        onPointerCancel: (_) { if (!isDanger) ref.read(roverProvider.notifier).stop(); },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDanger ? Colors.red.withOpacity(0.2) : Theme.of(context).colorScheme.primary.withOpacity(0.2),
            border: Border.all(color: isDanger ? Colors.red : Theme.of(context).colorScheme.primary),
          ),
          child: Icon(icon, size: 32, color: isDanger ? Colors.red : Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildJoystick() {
    const double outerRadius = 75.0;
    const double knobRadius = 30.0;
    const double maxDistance = outerRadius - knobRadius; // 45.0

    return GestureDetector(
      onPanUpdate: (details) {
        final center = const Offset(outerRadius, outerRadius);
        Offset offset = details.localPosition - center;
        
        // Clamp local offset to maxDistance
        if (offset.distance > maxDistance) {
          offset = Offset.fromDirection(offset.direction, maxDistance);
        }

        setState(() {
          _joystickOffset = offset;
        });

        // Trigger moves based on direction if distance is beyond a deadzone
        if (offset.distance > 15.0) {
          final angle = offset.direction; // -pi to pi
          if (angle >= -pi / 4 && angle < pi / 4) {
            ref.read(roverProvider.notifier).move('RIGHT');
          } else if (angle >= pi / 4 && angle < 3 * pi / 4) {
            ref.read(roverProvider.notifier).move('BACKWARD');
          } else if (angle >= -3 * pi / 4 && angle < -pi / 4) {
            ref.read(roverProvider.notifier).move('FORWARD');
          } else {
            ref.read(roverProvider.notifier).move('LEFT');
          }
        } else {
          ref.read(roverProvider.notifier).stop();
        }
      },
      onPanEnd: (_) {
        setState(() {
          _joystickOffset = Offset.zero;
        });
        ref.read(roverProvider.notifier).stop();
      },
      onPanCancel: () {
        setState(() {
          _joystickOffset = Offset.zero;
        });
        ref.read(roverProvider.notifier).stop();
      },
      child: Container(
        width: outerRadius * 2,
        height: outerRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), width: 2),
        ),
        child: Stack(
          children: [
            Positioned(
              left: outerRadius - knobRadius + _joystickOffset.dx,
              top: outerRadius - knobRadius + _joystickOffset.dy,
              child: Container(
                width: knobRadius * 2,
                height: knobRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: const Icon(LucideIcons.move, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
