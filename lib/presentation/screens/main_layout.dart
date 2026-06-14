import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/localization/translations.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    
    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNav(context, ref, location),
    );
  }

  Widget _buildBottomNav(BuildContext context, WidgetRef ref, String location) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(context, ref, LucideIcons.layoutDashboard, 'Home', '/dashboard', location),
            _buildNavItem(context, ref, LucideIcons.camera, 'Camera', '/camera', location),
            _buildNavItem(context, ref, LucideIcons.activity, 'Sensors', '/sensors', location),
            _buildNavItem(context, ref, LucideIcons.bot, 'Rover', '/rover', location),
            _buildNavItem(context, ref, LucideIcons.scanLine, 'Scan', '/scan', location),
            _buildNavItem(context, ref, LucideIcons.history, 'History', '/history', location),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, WidgetRef ref, IconData icon, String label, String route, String currentLocation) {
    final isSelected = currentLocation.startsWith(route);
    final theme = Theme.of(context);
    final color = isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6);

    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label.tr(ref), 
              style: theme.textTheme.labelSmall?.copyWith(
                color: color, 
                fontSize: 10, // slightly smaller text to fit 6 items
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
              ),
            ),
          ],
        ),
      ),
    );
  }
}
