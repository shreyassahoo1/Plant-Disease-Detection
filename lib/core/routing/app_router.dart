import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/camera/camera_screen.dart';
import '../../presentation/screens/sensors/sensors_screen.dart';
import '../../presentation/screens/rover/rover_screen.dart';
import '../../presentation/screens/scan/scan_screen.dart';
import '../../presentation/screens/history/history_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/main_layout.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/sensors',
          builder: (context, state) => const SensorsScreen(),
        ),
        GoRoute(
          path: '/camera',
          builder: (context, state) => const CameraScreen(),
        ),
        GoRoute(
          path: '/rover',
          builder: (context, state) => const RoverScreen(),
        ),
        GoRoute(
          path: '/scan',
          builder: (context, state) => const ScanScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
