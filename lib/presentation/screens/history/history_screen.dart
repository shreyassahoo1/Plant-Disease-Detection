import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/localization/translations.dart';
import '../../widgets/glass_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock History Data
    final mockHistory = [
      {'date': 'Today, 10:30 AM', 'title': 'Tomato Late Blight Detected', 'type': 'SCAN', 'severity': 'HIGH'},
      {'date': 'Yesterday, 2:15 PM', 'title': 'Healthy Crop Scanned', 'type': 'SCAN', 'severity': 'LOW'},
      {'date': 'Yesterday, 1:00 PM', 'title': 'High Temperature Alert', 'type': 'ALERT', 'severity': 'MEDIUM'},
      {'date': 'Oct 12, 09:00 AM', 'title': 'Rover Auto-Patrol Completed', 'type': 'ROVER', 'severity': 'INFO'},
      {'date': 'Oct 10, 11:20 AM', 'title': 'Wheat Rust Detected', 'type': 'SCAN', 'severity': 'MEDIUM'},
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('History Logs'.tr(ref)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: mockHistory.length,
        itemBuilder: (context, index) {
          final item = mockHistory[index];
          
          IconData icon;
          Color color;
          
          if (item['type'] == 'SCAN') {
            icon = LucideIcons.scan;
            color = item['severity'] == 'HIGH' ? Colors.red : (item['severity'] == 'MEDIUM' ? Colors.orange : Colors.green);
          } else if (item['type'] == 'ALERT') {
            icon = LucideIcons.bellRing;
            color = Colors.orange;
          } else {
            icon = LucideIcons.bot;
            color = Colors.blue;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title']!.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(item['date']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
