import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/localization/translations.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/esp32_cam_viewer.dart';

enum CameraViewMode { rover, static, split }

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  CameraViewMode _currentMode = CameraViewMode.rover;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Cameras'.tr(ref)),
        automaticallyImplyLeading: false, // No back arrow
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<CameraViewMode>(
              segments: const [
                ButtonSegment(
                  value: CameraViewMode.rover,
                  icon: Icon(LucideIcons.bot),
                  label: Text('Rover'),
                ),
                ButtonSegment(
                  value: CameraViewMode.static,
                  icon: Icon(LucideIcons.video),
                  label: Text('Static'),
                ),
                ButtonSegment(
                  value: CameraViewMode.split,
                  icon: Icon(LucideIcons.columns),
                  label: Text('Split'),
                ),
              ],
              selected: {_currentMode},
              onSelectionChanged: (Set<CameraViewMode> newSelection) {
                setState(() {
                  _currentMode = newSelection.first;
                });
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildCameraViews(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCameraViews() {
    final roverStreamUrl = dotenv.env['ROVER_ESP32_CAM_STREAM_URL'] ?? 'http://172.20.10.7:81/stream';
    final staticStreamUrl = dotenv.env['STATIC_ESP32_CAM_STREAM_URL'] ?? 'http://172.20.10.7:81/stream';

    if (_currentMode == CameraViewMode.split) {
      return Column(
        children: [
          Expanded(child: _buildCameraFeed('Rover Camera Feed', LucideIcons.bot, roverStreamUrl)),
          const SizedBox(height: 16),
          Expanded(child: _buildCameraFeed('Static Node Feed', LucideIcons.video, staticStreamUrl)),
        ],
      );
    } else if (_currentMode == CameraViewMode.rover) {
      return _buildCameraFeed('Rover Camera Feed', LucideIcons.bot, roverStreamUrl);
    } else {
      return _buildCameraFeed('Static Node Feed', LucideIcons.video, staticStreamUrl);
    }
  }

  Widget _buildCameraFeed(String title, IconData icon, String streamUrl) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ESP32CamViewer(streamUrl: streamUrl),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: const [
                  Icon(LucideIcons.radio, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
